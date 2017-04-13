# endeo
[![Build Status](https://travis-ci.org/elidoran/endeo.svg?branch=master)](https://travis-ci.org/elidoran/endeo)
[![Dependency Status](https://gemnasium.com/elidoran/endeo.png)](https://gemnasium.com/elidoran/endeo)
[![npm version](https://badge.fury.io/js/endeo.svg)](http://badge.fury.io/js/endeo)
[![Coverage Status](https://coveralls.io/repos/github/elidoran/endeo/badge.svg?branch=master)](https://coveralls.io/github/elidoran/endeo?branch=master)

Efficiently encode and decode objects, arrays, strings into binary data.

**en** code + **de** code = **o** bject

See packages:

1. [enbyte](https://www.npmjs.com/package/enbyte)
2. [debyte](https://www.npmjs.com/package/debyte)
3. [debytes](https://www.npmjs.com/package/debytes)
4. [destring](https://www.npmjs.com/package/destring)

NOTE: placeholder


## Install

```sh
npm install endeo --save
```


## Usage


```javascript
    // get the builder
var buildEndeo = require('endeo')

  // build one we can train
  , endeo = buildEndeo()

  // teach it how to serialize a specific object
  , serializer = endeo.add(function() {
    return {
      key1: null,
      key2: 'default value'
    }
  })

  // encode an object into a Buffer
  , buffer = serializer.encode({
      key1: 123, key2: 'something'
  })

  // decode the Buffer back into the object
  , object = serializer.decode(buffer)

  // object.key1 === 123
  // object.key2 === 'something'

  // OR: use the `endeo` to encode/decode.

  // this time, provide the ID in the object.
  , buffer = endeo.encode({
      $spec_id$: serializer.id,
      key1: 123, key2: 'something'
  })

  // OR: it's faster to say which type of value we're encoding:
  // NOTE: not as fast as using the serializer.encode()
  , buffer = endeo.object({
    $spec_id$: serializer.id,
    key1: 123, key2: 'something'
  })

  // decode the Buffer back into the object
  // could have done this above as well.
  // it's the same as serializer.decode(buffer).
  // the difference is `endeo` will read the
  // ID in the buffer to determine which serializer
  // to use. calling the serializer directly means it will
  // only validate it is the correct serializer.
  , object = endeo.decode(buffer)
```


# [MIT License](LICENSE)
