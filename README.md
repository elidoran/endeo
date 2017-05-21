# endeo
[![Build Status](https://travis-ci.org/elidoran/endeo.svg?branch=master)](https://travis-ci.org/elidoran/endeo)
[![Dependency Status](https://gemnasium.com/elidoran/endeo.png)](https://gemnasium.com/elidoran/endeo)
[![npm version](https://badge.fury.io/js/endeo.svg)](http://badge.fury.io/js/endeo)
[![Coverage Status](https://coveralls.io/repos/github/elidoran/endeo/badge.svg?branch=master)](https://coveralls.io/github/elidoran/endeo?branch=master)

Encode and decode objects, arrays, strings into bytes.

**endeo** => **en** code + **de** code = **o** bject

The majority of encode and decode work is done by packages [enbyte](https://www.npmjs.com/package/enbyte) and [debyte](https://www.npmjs.com/package/debyte). Their perspective is about the values they're given to encode and decode. For example, enbyte encodes `{}` as `EMPTY_OBJECT` and endeo encodes it as `[OBJECT, TERMINATOR]` (at top-level).

The [endeo](https://www.npmjs.com/package/endeo) package has the over-arching perspective of encoding and decoding values in sequence and handling streaming. It's possible to use [enbyte](https://www.npmjs.com/package/enbyte) and [debyte](https://www.npmjs.com/package/debyte) directly for a variety of uses. My main focus is on [endeo](https://www.npmjs.com/package/endeo) and providing all the features.

I've separated the parts into their own packages so they can be used standalone and, so they can be replaced with custom implementations in an endeo instance. Also, they have separate github repo's so they have their own issues/PR's.

The various parts can be developed and released separately.

See packages:

1. [endeo](https://www.npmjs.com/package/endeo)
2. [enbyte](https://www.npmjs.com/package/enbyte)
3. [debyte](https://www.npmjs.com/package/debyte)
4. [unstring](https://www.npmjs.com/package/unstring)
5. [@endeo/decoder](https://www.npmjs.com/package/@endeo/decoder)
5. [@endeo/bytes](https://www.npmjs.com/package/@endeo/bytes)
5. [@endeo/types](https://www.npmjs.com/package/@endeo/types)
5. [@endeo/input](https://www.npmjs.com/package/@endeo/input)
5. [@endeo/output](https://www.npmjs.com/package/@endeo/output)


##### TODO: TCK

I have an `@endeo/tck` package under development. It's a "test compatibility kit" with data to use when testing an implementation of endeo's encoding to ensure it works properly.

The above packages have tests to ensure they work. When I finish the TCK then they will also be tested with that.

The TCK will allow alternate implementations to ensure they adhere to the spec. The alternate implementations may be written in other node community languages such as TypeScript. Or, it could be in other languages such as Java and Go. I plan to make other language implementations, eventually.

##### TODO: objen

I have in development a package which reads an "object spec" from a JSON file.

I'm also going to make one which reads a Google Protocol Buffers ".proto" file to make a "creator function" and "enhancers" for an "object spec". This will allow using "proto" files with endeo to output endeo style encoding (not protobuf encoding).


## Install

```sh
# when using the standard implementations, use aggregator.
# endeo-std depends on all the standard implementations.
# usually, this is the one to use.
npm install --save endeo-std

# when specifying custom components.
# only use this when *replacing* some standard implementations.
npm install --save endeo
```

## Table of Contents

A. [Simplified Examples](#a-simplified-examples)

  1. [encode -> buffer -> decode](#a1-encode---buffer---decode)
  2. [encode/decode via transform streams](#a2-encodedecode-via-transform-streams)

B. [Progressively Enhanced Use](#b-progressively-enhanced-use)

  1. [generically encode any object](#b1-generically-encode-any-object)
  2. [reduce string bytes](#b2-reduce-string-bytes)
  3. [define an "object spec"](#b3-define-an-object-spec)
  4. [add "object spec" enhancers](#b4-add-object-spec-enhancers)
  5. [specify types](#b5-specify-types)

C. [API](#c-api)

  1. [builder/constructor](#c1-builderconstructor)
  2. [add() an object spec](#c2-add-an-object-spec)
  3. [create an input/output](#c3-create-an-inputoutput)
  4. [encode() to buffer](#c4-encode-to-buffer)
  5. [encoder() transform](#c5-encoder-transform)
  6. [decode() from buffer](#c6-decode-from-buffer)
  7. [decoder() transform](#c7-decoder-transform)

D. [Vocabulary](#d-vocabulary)
E. [Encoding Specification](#e-encoding-specification)
F. [MIT License](#LICENSE)


## A. Simplified Examples

### A1. encode -> buffer -> decode

```javascript
var result = endeo.encode({ key1: 123, key2: 'test' })

// result will have an `error` property if it error'd.
// has `buffer` when successful
var buffer = result.buffer

var object = endeo.decode(buffer, 0)
```


### A2. encode/decode via transform streams

```javascript
var encoder = endeo.encoder()
var decoder = endeo.decoder()

// for show (we wouldn't do this...)
encoder.pipe(decoder)

// add 'error' and 'data' events on either stream.
// encoder outputs Buffer.
// decoder outputs objects (object/array/String).

// this will be encoded into a Buffer,
// piped to decoder,
// and decoder will decode and push() it.
encoder.write({ key1: 123, key2: 'test' })
```


## B. Progressively Enhanced Use

### B1. generically encode any object

Any object can be encoded without special requirements.

```javascript
var object = getSomeObject()

var buffer = endeo.encode(object)

// or, knowing it's an object use the specific function:
var buffer = endeo.object(object)

// or, via the encoder transform:
var encoder = endeo.encoder()
encoder.write(object)
```


### B2. reduce string bytes

Replace strings with ID's to reduce bytes required.

An [unstring](https://www.npmjs.com/package/unstring) instance handles which strings are replaced. It has configurable restrictions controlling which strings it auto-learns. It also accepts strings at creation.

Provide expected strings for object keys and values.

```javascript
// the keys are always strings,
// these values are strings.
var object = {
  key1: 'value1',
  key2: 'value2'
}

// add 2 of the 4 strings to unstring
endeo.unstring.add('key1', 'value1')

// when encoding, key1/value1 are replaced with ID's.
var buffer = endeo.encode(object)
// or, directly:
var buffer = endeo.object(object)

// Note, if the unstring's restrictions allow the other 2 strings
// to be "auto-learned" then they will be encoded as strings
// only this first time to tell the receiver to learn the string.
// subsequent times they'll be replaced with ID's as well.
```


### B3. define an "object spec"

Configure endeo with an "object spec" for a known object key structure. Then it completely avoids sending keys.

Also, the "object spec" defines default values for the keys so default values are reduced to a single byte meaning "default".

An "object spec" is easily defined with an object. The keys map to the default values.

The object is provided from a function I'll call a "creator" function. It has multiple uses. Providing the object to define the "object spec" is one. It's also used at decoding time to create a new object to fill with the decoded values.

The "object spec" is remembered in endeo and retrieved when decoding. When encoding, it's provided to `objectWithSpec()` or embedded on the object with key `$ENDEO_SPECIAL`. A convenience method, `spec.imprint()` helps hide the property on an object or set it into a class's prototype.

```javascript
// the creator function:
function createThing() {
  // create a new instance each time:
  return {
    key1: null,    // default = null
    key2: 123,     // default = 123
    key3: 'string' // default = 'string'
  }
}

// add the "object spec"
var spec = endeo.add(createThing)

// our object has the same keys.
var object = {
  key1: 'one',
  key2: 12345,
  key3: 'string'
}

// encode with the spec:
var buffer = endeo.objectWithSpec(spec, object)

// Or, embed the spec:

// manual imprint:
object = {
  $ENDEO_SPECIAL: spec,
  key1: 'one',
  key2: 12345,
  key3: 'string'
}

// imprint via spec:
spec.imprint(object)

// class prototype embedding:
spec.imprint(MyThing.prototype)
object = new MyThing(1, 2)

// now, both encode() and special() will find the spec
// and do the special encoding.
buffer = endeo.encode(object)
// Or, go right to encoding a special object
buffer = endeo.special(object)
```


### B4. add "object spec" enhancers

Providing enhancers will alter how an "object spec" is used. Enhancers:

1. **type** - A type is a pre-defined enhancer. an `@endeo/specials` instance may be trained with types so the creator can reference them by name. Or, they can be specified in an enhancer's `type` property.
2. **encode** - A custom encode function to use for the value instead of analyzing it to determine how to encode it. Specifying this will speedup encoding by avoiding value analysis. It can also allow a custom byte encoding for the value. The function params are `(enbyte, value, output)`. See [enbyte](https://www.npmjs.com/package/enbyte) and [@endeo/output](https://www.npmjs.com/package/@endeo/output).
3. **decode** - A custom decode function. If you specify a custom `encode()` then use this to specify its `decode()`.
4. **decoderNode** - This is for streaming decode via [@endeo/decoder](https://www.npmjs.com/package/@endeo/decoder). Encoding combines streaming (chunk encoding) and "put it all in one buffer" by using [@endeo/output](https://www.npmjs.com/package/@endeo/output) to handle that. The [@endeo/input](https://www.npmjs.com/package/@endeo/input) doesn't do the same for decoding. So, there is `decode()` for "i have it all in one buffer ready to decode" and `decoderNode` for [@endeo/decoder](https://www.npmjs.com/package/@endeo/decoder) when streaming. See [stating](https://www.npmjs.com/package/stating) to understand how the node should be implemented. The function params are `(control, nodes, context)` as for all stating nodes.
5. **select** - when a key's value is always one from a set of values then provide the values in an array to the `select` property. In the creator function set the value of the key to the default value, as usual. This will encode the index of the value instead of the value itself.

How to specify enhancers:

```javascript
function createThing() {
  return {
    custom1: null,
    custom2: null,
    fruit: 'orange'
  }
}

// get some pre-defined types:
var types = require('@endeo/types')

// teach our @endeo/specials about the 'day' type.
endeo.specials.addType('day', types.day)

// only provide enhancers for the keys you want to enhance.
var enhancers = {
  // let's say custom1 is always an int fitting within 2 bytes.
  // use the pre-defined 2 byte int type.
  // it has a custom encode().
  custom1: types.int2,

  // let's say custom2 is a date, without time component.
  // use the pre-defined 'day' type.
  // reference it via its name because we added it to specials.
  custom2: 'day',

  // fruit will be a select of a few fruits:
  // specify as { select: [ ... ] }, or, shortcut:
  fruit: [ 'apple', 'banana', 'orange', 'kiwi' ]
}

// now add the "object spec" with both creator and enhancers
var spec = endeo.add(createThing, enhancers)

var object = {
  custom1: 12345,
  custom2: new Date(2001, 2, 3), // March 3rd, 2001.
  fruit: 'banana'
}

// and encode it as shown previously.
var buffer = endeo.objectWithSpec(object, spec)

// the `custom1` value will always be two bytes and
// encoding will happen without analyzing it to
// determine it's a number, an int, an int requiring 2 bytes.
// so, faster.

// the `custom2` value will be encoded using 4 bytes.
// 2 for year, 1 for month, 1 for day-of-month.
// that's less than Date's usual 24 bytes when
// encoding it as '2001-02-03T00:00:00.000Z',
// or 7 bytes for the Date.getTime() number.

// the `fruit` value will be encoded as `1` because
// 'banana' is at index 1 in the fruit enhancer's array.
// if the value was 'orange' then it'd be encoded as
// DEFAULT.
```


### B5. specify types

When encoding endeo must analyze each value to determine how to encode it.

Specify every value's type in an "object spec" via `enhancers` to avoid all analysis work.

For common values use pre-defined types in [@endeo/types](https://www.npmjs.com/package/@endeo/types).

Int values are a bit tricky. Endeo will use the fewest bytes needed to convey an int. It does this via analysis as well. If you know your int will always fit into a certain number of bytes then you may specify its type and it will always use the same number of bytes. This means a value which could have been encoded with less bytes will still use that larger number of bytes. And, if the value did exceed what can be conveyed with that number of bytes then its value will be mangled. You decide which way to go.

For complex values you may provide custom types as described above in #4.

For inner objects you can put them in the creator function's returned object if their key structure is consistent. Making it part of the "object spec". For varying keys the inner part will be encoded via generic object encoding (with unstring support) unless you provide a custom type. Note, it's also possible for inner objects to be special objects with their own "object spec".

When all values of a special object have a custom type enhancer with an `encode()` then encoding will proceed without any value analysis.


## C. API

### C1. builder/constructor

Endeo exports a builder function which calls the constructor.

It accepts options to configure the inner components or replace them entirely with custom implementations.

#### Build with Standard Implementations

Basic build will try to use "standard implementations" available both individually and conveniently with package `endeo-std`.

Install the packages:

```sh
# individually:
npm install --save @endeo/bytes enbyte debyte unstring @endeo/specials @endeo/decoder

# via aggregator:
npm install --save endeo-std
```

Standard component implementation packages:

1. [unstring](https://www.npmjs.com/package/unstring) - string cache for sending ID's instead of the strings
2. [@endeo/specials](https://www.npmjs.com/package/@endeo/specials) - builds "object specs"
3. [@endeo/bytes](https://www.npmjs.com/package/@endeo/bytes) - the byte markers
4. [enbyte](https://www.npmjs.com/package/enbyte) - does the majority of encode work
5. [debyte](https://www.npmjs.com/package/debyte) - does the majority of decode work
6. [@endeo/decoder](https://www.npmjs.com/package/@endeo/decoder) - transform for streaming decode work

```javascript
var buildEndeo = require('endeo')

// to build with the standard implementations:
// do: npm install -S endeo-std
// and no custom options.
var endeo = buildEndeo()

// customize standard implementations:
endeo = buildEndeo({
  // customize unstring:
  // only tell it strings to use
  strings: [ 'some', 'strings' ]
  // Or, give an entire options object to unstring:
  unstringOptions: {
    // see the unstring package for all its options
    strings: [ 'same', 'thing' ],
    min: 2,
    max: 100
  },

  // customize @endeo/specials with types to start with:
  types: {
    // see @endeo/specials, and @endeo/types for an example
    some: { /* type */ }
  }

  // customize enbyte:
  // it receives the unstring instance and bytes.

  // customize debyte:
  // it receives the unstring, bytes, and specs

  // customize @endeo/decoder:
  // it receives: bytes, specs, types, unstring, and unstringOptions.

  // add object specs:
  specs: [
    /* some "object spec" instances, see @endeo/specials */
  ]
})
```


#### Build with Custom Implementations

Customize every inner component with an alternate implementation:

```javascript
var buildEndeo = require('endeo')

var endeo = buildEndeo({
  Input: /* builder: function(buffer, index, options) */,
  Ouput: /* builder: function(writer, target) */,
  unstring: /* duck-typed unstring instance */,
  bytes: /* byte values object, see @endeo/bytes */,
  specials: /* duck-typed @endeo/specials instance */,
  enbyte: /* duck-typed enbyte instance */,
  debyte: /* duck-typed debyte instance */,
  encoder: /* function returns transform instance */,
  decoder: /* function returns transform, see @endeo/decoder */
})
```



### C2. add() an object spec

Endeo uses an [@endeo/specials](https://www.npmjs.com/package/@endeo/specials) instance to build an "object spec". Then, it retains them in an array and refers to them by their ID which is the index into that array.

A receiving endeo must have the same specs so the ID's map to the right specs.

An "object spec" can be built with nothing more than a simple object (returned by a "creator" function).

It may also have "enhancers" which augment its operations.

A "special object" with the "object spec" "imprinted" on it may be given to `encode()`, `object()`, and `special()` to encode it. Both `encode()` and `object()` will test for the spec and find it. The `special()` will get the spec from the imprinted property and error if it's not there.

Here's how to use a "creator function" and then how to make encoding use the "object spec":

```javascript
// a "creator" function builds a new object with
// the keys mapped to their default values.
function thing() {
  return {
    key1: 12345, // 12345 is now default value
    key2: null   // null is default value
  }
}

// teach it about the special object.
// not providing "enhancers" (arg 2)
var spec = endeo.add(creator)

var myThing = {
  key1: 2468,
  key2: 'test'
}

// this would encode `myThing` as a generic object:
var buffer = endeo.encode(myThing)
// Or:
buffer = endeo.object(myThing)

// and this errors because spec is missing:
buffer = endeo.special(myThing)

// ! provide the spec in one of 4 ways:

// 1. as an arg
buffer = endeo.objectWithSpec(myThing, spec)

// 2. by imprinting it
spec.imprint(myThing)
buffer = endeo.encode(myThing)
// Or:
buffer = endeo.special(myThing)

// 3. by setting it in object at creation time
myThing = {
  $ENDEO_SPECIAL: spec,
  key1: 2468,
  key2: 'test'
}

// 4. by imprinting it on a class's prototype
// imagine the extra stuff to make this a class is done.
function MyThing(key1, key2) {
  this.key1 = key1
  this.key2 = key2
}

spec.imprint(MyThing.prototype)
myThing = new MyThing(2468, 'test')

buffer = endeo.encode(myThing)
// Or:
buffer = endeo.special(myThing)
```

Here's how to provide "enhancers" for the "object spec":

```javascript
// assume we have thing() function from above as the creator.

// grab some pre-defined types:
var types = require('@endeo/types')

// teach endeo the one type we're going to use below.
// this allows referring to it via its name.
endeo.specials.addType('int2', types.int2)

// "enhancers" is an object mapping the "object spec" keys
// to extra info.
var enhancers = {
  // specify a pre-defined type by name:
  key1: 'int2',
  // Or, provide the type directly:
  key1: types.int2,

  // specify type here:
  key2: {
    // optional custom encode:
    encode: function (enbyte, value, output) {},

    // optional custom decode:
    decode: function (debyte, input) {},

    // optional custom decoderNode (for @endeo/decoder):
    decoderNode: function (control, N) {},

    // must be used exclusively, can't use others with this.
    // creates encode() decode() which uses index to refer
    // to which one is the value.
    select: [
      'some', 'values', 'to', 'choose', 'one', 'of'
    ],

    // optional, this will *combine* the info here with
    // the named pre-defined type.
    // these values override the one referenced.
    type: 'someType'
  }
}

// then provide it as the second arg to add().
var spec = endeo.add(thing, enhancers)
```


### C3. create an input/output

Both [input](https://www.npmjs.com/package/@endeo/input) and [output](https://www.npmjs.com/package/@endeo/output) help with working with a buffer. Output goes beyond that and helps output buffer chunks for streaming or combine them all into a single buffer for the final result.

An [output](https://www.npmjs.com/package/@endeo/output) may be reused in sequential encode operations. Endeo helps build one with a convenience method `output()`. It will use the standard implementation unless endeo was built with a custom one.

```javascript
// this output will build up buffer chunks as encoding progresses.
var output = endeo.output()

// get all the chunks in one buffer:
var result = output.complete()
// result either has `error` or `buffer`
var buffer = result.buffer

// or, have the output written to a stream:
var output = endeo.output(writable.write, writable)
// Or, a transform:
var output = endeo.output(transform.push, transform)

// chunks will be sent as they fill up.
// flush out remaining content using the same function:
output.complete()

// control the chunk sizes:
output.size = 2048

// Note, written chunk size may vary when output decides
// to send a non-full chunk because it has a large value
// to send as its own chunk.
// You probably won't ever notice, but, I want to mention it
// in case someone decides to do something based on the idea
// the chunk size will always being the same. It won't.

// also, you may choose to *not* call output.complete() after
// giving it something to encode. Later encoding operations
// will fill the chunk and send it, eventually.
// be sure to at least call it once when you're done encoding
// everything.
```

An [input](https://www.npmjs.com/package/@endeo/input) helps track where in the buffer the decode operation is at and extracts values. It may be reused by calling `reset()` with a new buffer and index. Endeo helps build one with a convenience method `input()`. It will use the standard implementation unless endeo was built with a custom one.

```javascript
// provide a buffer and the index to start at.
var input = endeo.input(buffer, 0 /* , options */)

// you may provide the buffer/index via properties in the
// options (3rd arg).
// I originally had the options as the only arg,
// but, it seemed a waste when I was always using buffer/index
// all the time.
// so, they are now the first two args.
// I maintain an options 3rd arg in case someone wants to
// put the new buffer/index in an object to pass on to
// another place which receives that and then creates an Input
// (or resets one) with it.
var input = endeo.input(null, null, {
  buffer: someBuffer, index: 0
})

// reset the Input with a new buffer/index:
input.reset(newBuffer, 0)
```


### C4. encode() to buffer

Endeo can encode a value into a single Buffer via multiple "entry points".

The "entry points":

1. `encode()` - encodes any "top level" value (object, array, string)
2. `object()` - encodes any object, special or generic
3. `objectWithSpec()` - encodes only "special objects" with the provided "object spec"
4. `special()` - encodes only a "special object" with an "imprinted" "object spec"
5. `array()` - encodes an array
6. `string()` - encodes a string

```javascript
// encode()
endeo.encode({ some: object})
endeo.encode([ 'some', 'array' ])
endeo.encode('some string')

// object()
endeo.object({ generic: 'object' })
endeo.object({ special: 'object, (imprinted)' })
endeo.object({ // manual imprint:
  $ENDEO_SPECIAL: spec,
  /* key/values */
})

// objectWithSpec()
endeo.objectWithSpec({ some: 'object' }, spec)

// special()
endeo.special({ special: 'imprinted' })
endeo.special({ // manually imprinted
  $ENDEO_SPECIAL: spec,
  /* key/values */
})

// array()
endeo.array([ 'some', 'array' ])

// string()
endeo.string('some string')
```

All the above "entry points" create an `output` to gather all the chunks and provide the result as a single buffer.

To output the chunks to a stream use `decoder()` as decribed below in [C7. decoder() transform](#c7-decoder-transform). Or, create your own output and call the inner versions of the "entry points":

```javascript
var output = endeo.output(stream.write, stream)

endeo._encode(value, output)
endeo._object(value, output)
endeo._objectWithSpec(value, spec, output)
endeo._special(value, output)
endeo._array(value, output)
endeo._string(value, output)

// these all call output.complete() when they're done.
// the chunks are sent to the stream so the result
// returned is:  { success: true }

// you may continue to reuse `output`.
```


### C5. encoder() transform

Endeo makes it easy to stream. The `encoder()` creates a new `Transform` you can use in pipelines or write to directly.

The encoder calls `endeo.encode()` to encode the objects it receives.

The `@endeo/output` then pushes buffer chunks as they fill up.

```javascript
var encoder = endeo.encoder()

// usual event style:
encoder.on('error', function(error) {
  // ...
})
encoder.on('data', function(buffer) {
  // ...
})

// usual pipe():
source.pipe(encoder).pipe(target)

// or write to it directly:
encoder.write({ some: 'object' })
encoder.write([ 'some', 'array' ])

// a "string" is a "top level" value.
// however, writing a string requires writableObjectMode = false.
// and encoder defaults to writableObjectMode = true.
// so, if you want to use "top level" strings,
// then make an encoder with writableObjectMode set to false:
encoder = endeo.encoder({
  writableObjectMode: false
})

// then:
encoder.write('some string')
```


### C6. decode() from buffer

Endeo can decode a value from a single Buffer via multiple "entry points".

To differentiate from encoding operations prepend 'de' to the names.

The "entry points":

1. `decode()` - decodes any "top level" value (object, array, string)
2. `deobject()` - decodes any object, special or generic
3. `despecial()` - decodes only a "special object" with an ID
4. `dearray()` - decodes an array
5. `destring()` - decodes a string

```javascript
var buffer = getSomeEncodedBuffer()
result = endeo.decode(buffer, 0)
result = endeo.deobject(buffer, 0)
result = endeo.despecial(buffer, 0)
result = endeo.dearray(buffer, 0)
result = endeo.destring(buffer, 0)
```

All the above "entry points" create an `input` for the buffer and index.

Create your own input and call the inner versions of the "entry points":

```javascript
var input = endeo.input(buffer, 0)

result = endeo._decode(input)
result = endeo._deobject(input)
result = endeo._despecial(input)
result = endeo._dearray(input)
result = endeo._destring(input)

// you may continue to reuse `input`
// by resetting it with a new buffer/index:
input.reset(newBuffer, 0)
```



### C7. decoder() transform

Endeo makes it easy to stream. The `decoder()` creates a new `Transform` you can use in pipelines or write to directly.

The "standard implementation" for decoder is a `Transform` created by [@endeo/decoder](https://www.npmjs.com/package/@endeo/decoder). It uses the [stating](https://www.npmjs.com/package/stating) package.

Write, or pipe, Buffer's to the decoder and it will `push()`, and emit "data" events, with the decoded result.

```javascript
var decoder = endeo.decoder()

// usual event style:
decoder.on('error', function(error) {
  // ...
})
decoder.on('data', function(result) {
  // ...
})

// usual pipe():
source.pipe(decoder).pipe(target)

// or write to it directly:
decoder.write(someBuffer)
decoder.write(anotherBuffer)

// a "string" is a "top level" value.
// however, push()'ing a string will error when
// writableObjectMode = true.
// at the moment, @endeo/decoder cheats by
// converting a string to a String so it's an object.
// in the future, it will have an alternate solution.
```



## D. Vocabulary

Words and phrases I use while describing endeo stuff:


word/phrase    |  description
--------------:|:--------------------------------------------------------------------
endeo          | name of the whole project, the spec, and the primary package
object spec    | knows sequence of keys, their default values, optionally custom operations
special object | an object **with** an "object spec"
generic        | an object **without** an "object spec"
creator        | function returning new object with keys and default values for an "object spec"
enhancer       | extra information to augment an "object spec" beyond the key and default value
marker         | a byte with specific meaning in endeo encoding, such as `ARRAY`.
encoder        | a transform stream which accepts objects and outputs Buffer's
decoder        | a transform stream which accepts Buffer's (chunks of one thing, or chunks with multiple things, or partials) and outputs objects (or arrays, or String [cuz string isn't an object...])
auto-learn     | an "unstring" instance may "learn" a new string when asked for its ID if restrictions allow it.
unstring       | a package which caches strings, has configurable restrictions for auto-learning strings, and reduces bytes sent by replacing strings with their ID
specials       | an instance of package `@endeo/specials` which can be trained with custom types and analyses a "creator" and "enhancers" to produce an "object spec"
imprint        | an "object spec" may be provided as an arg to `objectWithSpec()` along with the object value. When I say "imprint" it, I mean either set the spec into the object with key `$ENDEO_SPECIAL`, use spec's `imprint()` method to set it on an object, or a class's prototype. The `imprint()` method sets `$ENDEO_SPECIAL` as a non-enumerable non-writable property on the target.
standard       | I'm providing implementations for each part of the endeo work. When I say "standard" I mean these implementations I've made. To allow using endeo with custom implementations the `endeo` package doesn't have the "standard implementations" as dependencies. To install a single package which depends on all the "standard implementations" use the `endeo-std` package. It has no code content. It only depends on all the "standard implementations" so they'll be installed. It's a "package aggregator".
top level      | endeo considers an object, array, or string to be a "top level" object. A "full chunk" has one of those three.
full chunk     | a group of bytes which can be decoded into an object, array, or string.
entry point    | there are multiple functions to encode and decode. these are "entry points". The `encode()` and `decode()` are the most generic "entry points" capable of handling any "top level" value. There are other functions for specific types of "top level" value. When you know the type you may use these to "get right to it".


## E. Encoding Specification

.


# F. [MIT License](LICENSE)
