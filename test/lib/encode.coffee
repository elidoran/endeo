assert = require 'assert'
flatten = require '@flatten/array'

B = require '@endeo/bytes'
buildUnstring = require 'unstring'
denyingUnstring = buildUnstring limit:0

build = require '../../lib/index.coffee'

buildStringBuffer = (string) ->
  if string.length < 1
    answer = Buffer.alloc 3
    answer[0] = B.STRING
    answer[1] = B.EMPTY_STRING
    answer[2] = B.TERMINATOR

  else
    length = Buffer.byteLength string
    answer = Buffer.alloc length + 3
    answer[0] = B.STRING
    answer[1] = length
    answer.write string, 2, length, 'utf8'
    answer[answer.length - 1] = B.TERMINATOR

  return answer

stringBuffer = (string) -> [
  Buffer.from [ B.STRING, string.length ]
  Buffer.from string
]

OBJECT_BUFFER         = do -> buf = Buffer.alloc 1 ; buf[0] = B.OBJECT ; buf
ARRAY_BUFFER          = do -> buf = Buffer.alloc 1 ; buf[0] = B.ARRAY ; buf
SUB_TERMINATOR_BUFFER = do -> buf = Buffer.alloc 1 ; buf[0] = B.SUB_TERMINATOR ; buf
TERMINATOR_BUFFER     = do -> buf = Buffer.alloc 1 ; buf[0] = B.TERMINATOR ; buf

buildObjectBuffer = (array) ->

  if array.length < 1
    answer = Buffer.alloc 2
    answer[0] = B.OBJECT
    answer[1] = B.TERMINATOR
    return answer

  else
    array.push TERMINATOR_BUFFER
    Buffer.concat array

showBuffers = (actual, expected) ->
  if expected.length <= 40
    console.log 'answer:', expected
    console.log 'actual:', actual

  else
    i = 0
    while i < expected.length
      console.log 'answer:', expected.slice i, i + 40
      console.log 'actual:', actual.slice i, i + 40
      console.log ''
      i += 40


describe 'test endeo', ->

  it 'should build', -> assert build()

  it 'should add an object spec', ->

    endeo = build()
    result = endeo.add -> s:'s', one:1, a:[ 1, '2', three:3 ]
    assert result
    assert.equal result.id, 0
    assert result.array


  it 'should add an object spec via constructor option', ->

    endeo = build specs: [ -> s:'s', one:1, a:[ 1, '2', three:3 ] ]

    result = endeo.specs[0]
    assert result
    assert.equal result.id, 0
    assert result.array


  it 'should error when adding non-creator function', ->

    endeo = build()
    result = endeo.add null
    assert result?.error


  it 'should imprint on object provided', ->

    target = {}
    endeo = build()
    spec = endeo.add (-> a:1), null, target
    assert spec
    assert target.$ENDEO_SPECIAL
    assert.equal spec, target.$ENDEO_SPECIAL


  it 'should send objects to object()', ->

    endeo = build unstring:denyingUnstring
    called = false
    endeo._object = -> called = true
    endeo.encode {a:1}
    assert called


  it 'should send arrays to array()', ->

    endeo = build unstring:denyingUnstring
    called = false
    endeo._array = -> called = true
    endeo.encode [1]
    assert called


  it 'should send string to string()', ->

    endeo = build unstring:denyingUnstring
    called = false
    endeo._string = -> called = true
    endeo.encode 'testing'
    assert called


  it 'should error for invalid type', ->

    endeo = build unstring:denyingUnstring
    result = endeo.encode -1
    assert result?.error


  it 'should encode an EMPTY string', ->

    answer = Buffer.from [ B.STRING, B.TERMINATOR ]
    endeo = build()
    result = endeo.string ''
    # showBuffers answer, result.buffer
    assert.equal result.buffer.equals(answer), true

  it 'should encode a string', ->

    answer = Buffer.concat flatten [
      stringBuffer 'testing'
      TERMINATOR_BUFFER
    ]
    endeo = build unstring:denyingUnstring
    result = endeo.string 'testing'
    # showBuffers answer, result.buffer
    assert.equal result.buffer.equals(answer), true


  it 'should encode a known string', ->

    answer = Buffer.concat flatten [
      Buffer.from [ B.STRING, B.GET_STRING, 0 ]
      TERMINATOR_BUFFER
    ]
    endeo = build unstring: buildUnstring strings: [ 'testing' ]
    result = endeo.string 'testing'
    # showBuffers answer, result.buffer
    assert.equal result.buffer.equals(answer), true


  it 'should encode a learned string', ->

    answer = Buffer.concat flatten [
      Buffer.from [ B.STRING, B.NEW_STRING, 0, 7 ]
      Buffer.from 'testing'
      TERMINATOR_BUFFER
    ]
    endeo = build()
    result = endeo.string 'testing'
    # showBuffers answer, result.buffer
    assert.equal result.buffer.equals(answer), true


  it 'should encode a long string', ->

    base = '1234567890'
    string = ''
    string = string + base for i in [0 ... 40]
    answer = Buffer.concat flatten [
      Buffer.from [ B.STRING, B.P2, 0, 43 ]
      Buffer.from string
      TERMINATOR_BUFFER
    ]
    endeo = build unstring:denyingUnstring
    result = endeo.string string
    # showBuffers answer, result.buffer
    assert.equal result.buffer.equals(answer), true


  it 'should encode an EMPTY array', ->
    answer = Buffer.from [ B.ARRAY, B.TERMINATOR ]
    endeo = build()
    result = endeo.array []
    # console.log 'answer:', answer
    # console.log 'buffer:', result.buffer
    assert.equal result.buffer.equals(answer), true

  it 'should encode an array with a string', ->
    string = 'testing'
    answer = Buffer.concat flatten [
      Buffer.from [ B.ARRAY ]
      stringBuffer string
      TERMINATOR_BUFFER
    ]
    endeo = build unstring:denyingUnstring
    result = endeo.array [ string ]
    # showBuffers answer, result.buffer
    assert.equal result.buffer.equals(answer), true


  it 'should encode an array with a known string', ->
    string = 'testing'
    answer = Buffer.concat flatten [
      Buffer.from [ B.ARRAY ]
      Buffer.from [ B.GET_STRING, 0 ]
      TERMINATOR_BUFFER
    ]
    endeo = build unstring: buildUnstring strings: [ string ]
    result = endeo.array [ string ]
    # showBuffers answer, result.buffer
    assert.equal result.buffer.equals(answer), true


  it 'should encode an array with a learned string', ->
    string = 'testing'
    answer = Buffer.concat flatten [
      Buffer.from [ B.ARRAY ]
      Buffer.from [ B.NEW_STRING, 0, 7 ]
      Buffer.from string
      TERMINATOR_BUFFER
    ]
    endeo = build()
    result = endeo.array [ string ]
    assert.equal result.buffer.equals(answer), true


  it 'should encode an array with a special int', ->
    value = 1
    answer = Buffer.concat flatten [
      Buffer.from [ B.ARRAY, value ]
      TERMINATOR_BUFFER
    ]
    endeo = build()
    result = endeo.array [ value ]
    assert.equal result.buffer.equals(answer), true


  it 'should encode an array with a tiny int', ->
    value = 101
    answer = Buffer.concat flatten [
      Buffer.from [ B.ARRAY, B.P1, 0 ] # 0 because 101 - 101 = 0
      TERMINATOR_BUFFER
    ]
    endeo = build()
    result = endeo.array [ value ]
    assert.equal result.buffer.equals(answer), true


  it 'should encode an array with a small int', ->
    value = 357
    answer = Buffer.concat flatten [
      Buffer.from [ B.ARRAY, B.P2, 0, 0 ] # 0 because 357 - 357 = 0
      TERMINATOR_BUFFER
    ]
    endeo = build()
    result = endeo.array [ value ]
    # showBuffers answer, result.buffer
    assert.equal result.buffer.equals(answer), true


  it 'should encode an array with a medium int', ->
    value = 65893
    answer = Buffer.concat flatten [
      Buffer.from [ B.ARRAY, B.P3, 0, 0, 0 ] # 0 because 65893 - 65893 = 0
      TERMINATOR_BUFFER
    ]
    endeo = build()
    result = endeo.array [ value ]
    # showBuffers answer, result.buffer
    assert.equal result.buffer.equals(answer), true


  it 'should encode an array with a large int', ->
    value = 16843109
    answer = Buffer.concat flatten [
      # 0 because 16843109 - 16843109 = 0
      Buffer.from [ B.ARRAY, B.P4, 0, 0, 0, 0 ]
      TERMINATOR_BUFFER
    ]
    endeo = build()
    result = endeo.array [ value ]
    # showBuffers answer, result.buffer
    assert.equal result.buffer.equals(answer), true


  it 'should encode an array with a larger int', ->
    value = 4311810405
    answer = Buffer.concat flatten [
      # 0 because 4311810405 - 4311810405 = 0
      Buffer.from [ B.ARRAY, B.P5, 0, 0, 0, 0, 0 ]
      TERMINATOR_BUFFER
    ]
    endeo = build()
    result = endeo.array [ value ]
    # showBuffers answer, result.buffer
    assert.equal result.buffer.equals(answer), true


  it 'should encode an array with a largerer int', ->
    value = 1103823438181
    answer = Buffer.concat flatten [
      # 0 because 1103823438181 - 1103823438181 = 0
      Buffer.from [ B.ARRAY, B.P6, 0, 0, 0, 0, 0, 0 ]
      TERMINATOR_BUFFER
    ]
    endeo = build()
    result = endeo.array [ value ]
    # showBuffers answer, result.buffer
    assert.equal result.buffer.equals(answer), true


  it 'should encode an array with a largest int', ->
    value = 282578800148837
    answer = Buffer.concat flatten [
      # different than the others cuz we don't skew the value
      # because we can't extend the value range
      # because the best we can do is 53 bits.
      Buffer.from [ B.ARRAY, B.P7, 1, 1, 1, 1, 1, 1, 0x65 ]
      TERMINATOR_BUFFER
    ]
    endeo = build()
    result = endeo.array [ value ]
    # showBuffers answer, result.buffer
    assert.equal result.buffer.equals(answer), true


  it 'should encode an array with a max int', ->
    value = 9007199254740992
    answer = Buffer.concat flatten [
      # different
      Buffer.from [ B.ARRAY, B.P7, 0x20, 0, 0, 0, 0, 0, 0 ]
      TERMINATOR_BUFFER
    ]
    endeo = build()
    result = endeo.array [ value ]
    # showBuffers answer, result.buffer
    assert.equal result.buffer.equals(answer), true


  it 'should encode an array multiple depths of arrays inside', ->
    answer = Buffer.concat flatten [
      # different
      Buffer.from [
        B.ARRAY
        1
        B.ARRAY, 2, B.SUB_TERMINATOR
        3
        B.ARRAY, 4, 5, B.SUB_TERMINATOR
        6
        B.ARRAY, 7, B.ARRAY, 8, B.SUB_TERMINATOR, 9, B.SUB_TERMINATOR
        10
        B.ARRAY, 11, B.ARRAY, 12, B.ARRAY, 13, B.ARRAY, 14, 15, B.SUB_TERMINATOR, 16, B.SUB_TERMINATOR, 17
        B.TERMINATOR
      ]
    ]
    endeo = build()
    result = endeo.array [
      1,
      [ 2 ],
      3,
      [ 4, 5 ],
      6,
      [ 7, [ 8 ], 9 ],
      10,
      [ 11, [ 12, [ 13, [ 14, 15 ], 16 ], 17 ] ]
    ]
    # showBuffers answer, result.buffer
    assert.equal result.buffer.equals(answer), true


  it 'should encode an EMPTY object', ->

    answer = Buffer.from [ B.OBJECT, B.TERMINATOR ]
    endeo = build()
    result = endeo.object {}
    assert.equal result.buffer.equals(answer), true

  it 'should encode a generic object with single string value', ->
    string1 = 'some'
    string2 = 'value'
    answer = Buffer.concat flatten [
      Buffer.from [ B.OBJECT ]
      stringBuffer string1
      stringBuffer string2
      TERMINATOR_BUFFER
    ]
    endeo = build unstring:denyingUnstring
    result = endeo.object some: 'value'
    # console.log 'answer:', answer
    # console.log 'buffer:', result.buffer
    assert.equal result.buffer.equals(answer), true

  it 'should encode a generic object with single array value', ->
    string1 = 'some'
    string2 = 'array'
    array = [ string2 ]
    answer = Buffer.concat flatten [
      Buffer.from [ B.OBJECT ]
      stringBuffer string1
      Buffer.from [ B.ARRAY ]
      stringBuffer string2
      TERMINATOR_BUFFER
    ]
    endeo = build unstring:denyingUnstring
    result = endeo.object some: array
    # console.log 'answer:', answer
    # console.log 'buffer:', result.buffer
    assert.equal result.buffer.equals(answer), true

  it 'should encode a generic object with both string/array values', ->
    string1 = 'some'
    string2 = 'value'
    string3 = 'array'
    array = [ string3 ]
    answer = Buffer.concat flatten [
      Buffer.from [ B.OBJECT ]
      stringBuffer string1
      stringBuffer string2
      stringBuffer string3
      Buffer.from [ B.ARRAY ]
      stringBuffer string3
      TERMINATOR_BUFFER
    ]
    endeo = build unstring:denyingUnstring
    result = endeo.object some: 'value', array: array
    # console.log 'answer:', answer
    # console.log 'buffer:', result.buffer
    assert.equal result.buffer.equals(answer), true

  it 'should encode a generic object with multiple string/array values', ->
    string1 = 'some'
    string2 = 'value'
    string3 = 'something'
    string4 = 'else'
    string5 = 'array'
    string6 = 'another'
    string7 = 'thing'
    string8 = 'array2'
    string9 = 'array3'
    array1 = [ string5 ]
    array2 = [ string1, string5 ]
    array3 = [ string6, string5, string9 ]

    answer = Buffer.concat flatten [
      Buffer.from [ B.OBJECT ]
      stringBuffer string1
      stringBuffer string2
      stringBuffer string3
      stringBuffer string4
      stringBuffer string5
      Buffer.from [ B.ARRAY ]
      stringBuffer string5
      SUB_TERMINATOR_BUFFER
      stringBuffer string6
      stringBuffer string7
      stringBuffer string8
      Buffer.from [ B.ARRAY ]
      stringBuffer string1
      stringBuffer string5
      SUB_TERMINATOR_BUFFER
      stringBuffer string9
      Buffer.from [ B.ARRAY ]
      stringBuffer string6
      stringBuffer string5
      stringBuffer string9
      TERMINATOR_BUFFER
    ]

    endeo = build unstring:denyingUnstring
    result = endeo.object
      some: 'value'
      something: 'else'
      array: array1
      another: 'thing'
      array2: array2
      array3: array3

    # showBuffers answer, result.buffer
    for i in [0 ... result.buffer.length ]
      actual = result.buffer[i]
      expected = answer[i]
      assert.equal actual, expected, 'byte mismatch at ' + i


  it 'should encode a nested object in a generic object', ->

    string1 = 'some'
    string2 = 'object'
    string3 = 'child'

    object =
      some: string2
      child:
        some: string3

    answer = Buffer.concat flatten [
      OBJECT_BUFFER
      stringBuffer string1
      stringBuffer string2
      stringBuffer string3
      OBJECT_BUFFER
      stringBuffer string1
      stringBuffer string3
      TERMINATOR_BUFFER
    ]

    endeo = build unstring:denyingUnstring
    result = endeo.object object

    # showBuffers answer, result.buffer

    for i in [0 ... result.buffer.length ]
      actual = result.buffer[i]
      expected = answer[i]
      assert.equal actual, expected, 'byte mismatch at ' + i


  it 'should encode three nested objects in a generic object', ->

    string1 = 'some'
    string2 = 'string'
    string3 = 'child'
    string4 = 'first'
    string5 = 'another'
    string6 = 'child2'
    string7 = 'second'
    string8 = 'child3'
    string9 = 'third'

    object =
      some: string2
      child:
        first: string3
      another: string2
      child2:
        second: string3
      child3:
        third: string3


    answer = Buffer.concat flatten [
      OBJECT_BUFFER
      stringBuffer string1
      stringBuffer string2
      stringBuffer string3
      OBJECT_BUFFER
      stringBuffer string4
      stringBuffer string3
      SUB_TERMINATOR_BUFFER
      stringBuffer string5
      stringBuffer string2
      stringBuffer string6
      OBJECT_BUFFER
      stringBuffer string7
      stringBuffer string3
      SUB_TERMINATOR_BUFFER
      stringBuffer string8
      OBJECT_BUFFER
      stringBuffer string9
      stringBuffer string3
      TERMINATOR_BUFFER
    ]

    endeo = build unstring:denyingUnstring
    result = endeo.object object

    # showBuffers answer, result.buffer

    for i in [0 ... result.buffer.length ]
      actual = result.buffer[i]
      expected = answer[i]
      assert.equal actual, expected, 'byte mismatch at ' + i

  [ 'object', 'special' ].forEach (method) ->

    it 'should encode a spec\'d object via ' + method + ' (defaults)', ->

      creator = -> s:'s', one:1, a:[ 1, '2', 'abc' ]
      answer = Buffer.concat flatten [
        Buffer.from [
          0 # object spec id is zero so it's the first byte.
          # these are in sorted order
          B.DEFAULT # `a` is default value
          B.DEFAULT # `one` is default value
          B.DEFAULT # `s` is default value
        ]
        TERMINATOR_BUFFER
      ]
      object = creator() # use default one...

      endeo = build unstring:denyingUnstring
      spec = endeo.add creator # no enhancers, no proto
      assert spec
      assert.equal spec.id, 0

      spec.imprint object
      result = endeo[method] object

      assert result, 'should have a result'
      buffer = result.buffer

      assert.equal Buffer.isBuffer(buffer), true, 'should have a buffer'
      # showBuffers buffer, answer
      assert.deepEqual buffer, answer


    it 'should encode a spec\'d object via ' + method, ->

      creator = -> s:'s', one:1, a:[ 1, '2', 'abc' ]

      object = s:'string', one:100, a: [ '1', 2, 'def' ]

      answer = Buffer.concat flatten [
        # object spec id is zero so it's the first byte.
        Buffer.from [ 0 ]
        # these are in sorted order (as in the spec)
        Buffer.from [ B.ARRAY ]
        stringBuffer '1'
        Buffer.from [ 2 ]
        stringBuffer 'def'
        SUB_TERMINATOR_BUFFER
        Buffer.from [ 100 ]
        stringBuffer 'string'
        TERMINATOR_BUFFER
      ]

      endeo = build unstring:denyingUnstring
      spec = endeo.add creator # no enhancers, no proto
      assert spec
      assert.equal spec.id, 0

      spec.imprint object
      result = endeo[method] object

      assert result, 'should have a result'
      buffer = result.buffer

      assert.equal Buffer.isBuffer(buffer), true, 'should have a buffer'
      # showBuffers buffer, answer
      assert.deepEqual buffer, answer


    it 'should encode a generic object nested in a spec\'d object via ' + method + ' (defaults)', ->

      creator = -> s:'s', num:1, o: {a:'a', z:0}

      object = creator() # use default one...

      answer = Buffer.concat flatten [
        Buffer.from [
          0 # object spec id is zero so it's the first byte.
          # these are in sorted order
          B.DEFAULT # `num` is default value
          B.DEFAULT # `o` is default value
          B.DEFAULT # `s` is default value
        ]
        TERMINATOR_BUFFER
      ]

      endeo = build unstring:denyingUnstring
      spec = endeo.add creator # no enhancers, no proto
      assert spec
      assert.equal spec.id, 0

      spec.imprint object
      result = endeo[method] object

      assert result, 'should have a result'
      buffer = result.buffer

      assert.equal Buffer.isBuffer(buffer), true, 'should have a buffer'
      # showBuffers buffer, answer
      assert.deepEqual buffer, answer


    it 'should encode a generic object nested in a spec\'d object via ' + method, ->

      creator = -> s:'s', num:1, o: {a:'a', z:0}

      object = s:'string', num:100, o: {a:'aaa', z:-1}

      answer = Buffer.concat flatten [
        # object spec id is zero so it's the first byte.
        Buffer.from [ 0 ]
        # these are in sorted order (as in the spec)
        Buffer.from [ 100 ]

        stringBuffer 'aaa'
        Buffer.from [ 101 ]

        stringBuffer 'string'

        TERMINATOR_BUFFER
      ]

      endeo = build unstring:denyingUnstring
      spec = endeo.add creator # no enhancers, no proto
      assert spec
      assert.equal spec.id, 0

      spec.imprint object
      result = endeo[method] object

      assert result, 'should have a result'
      buffer = result.buffer

      assert.equal Buffer.isBuffer(buffer), true, 'should have a buffer'
      # showBuffers buffer, answer
      assert.deepEqual buffer, answer



    it 'should encode a spec\'d object provided as a surprise property in a spec\'d object' + method + ' (defaults)', ->

      creator1 = -> a:1, b:null, c:5
      creator2 = -> d:2, e:[ 3 ], f:4

      object =
        a: 1
        b:
          d: 2
          e: [ 3 ]
          f: 4
        c: 5

      answer = Buffer.concat flatten [
        Buffer.from [
          0 # object spec id is zero so it's the first byte.
          # these are in sorted order
          B.DEFAULT # `a` is default value

          B.SPECIAL
          1 # second object's spec id is 1
          B.DEFAULT
          B.DEFAULT
          B.DEFAULT
          B.SUB_TERMINATOR

          B.DEFAULT # `c` is default value
        ]
        TERMINATOR_BUFFER
      ]

      endeo = build unstring:denyingUnstring

      spec = endeo.add creator1 # no enhancers, no proto
      assert spec
      assert.equal spec.id, 0
      spec.imprint object

      spec = endeo.add creator2 # no enhancers, no proto
      assert spec
      assert.equal spec.id, 1
      spec.imprint object.b

      result = endeo[method] object

      assert result, 'should have a result'
      buffer = result.buffer

      assert.equal Buffer.isBuffer(buffer), true, 'should have a buffer'
      # showBuffers buffer, answer
      assert.deepEqual buffer, answer


    it 'should encode a spec\'d object provided as a surprise property in a spec\'d object via ' + method, ->

      creator1 = -> a:1, b:null, c:5
      creator2 = -> d:2, e:[ 3 ], f:4

      object =
        a: 11
        b:
          d: 22
          e: [ 33 ]
          f: 44
        c: 55

      answer = Buffer.from [
        0 # object spec id is zero so it's the first byte.

        # these are in sorted order (as in the spec)
        11 # a

        B.SPECIAL # b
        1 # second object's spec id is 1
        22 # d
        B.ARRAY # e
        33
        B.SUB_TERMINATOR
        44 # f
        B.SUB_TERMINATOR

        55 # c
        B.TERMINATOR
      ]

      endeo = build unstring:denyingUnstring

      spec = endeo.add creator1 # no enhancers, no proto
      assert spec
      assert.equal spec.id, 0
      spec.imprint object

      spec = endeo.add creator2 # no enhancers, no proto
      assert spec
      assert.equal spec.id, 1
      spec.imprint object.b

      result = endeo[method] object

      assert result, 'should have a result'
      buffer = result.buffer

      assert.equal Buffer.isBuffer(buffer), true, 'should have a buffer'
      # showBuffers buffer, answer
      assert.deepEqual buffer, answer


    it 'should encode a spec\'d class instance ' + method + ' (defaults)', ->

      answer = Buffer.from [
        0 # object spec id is zero so it's the first byte.

        # these are in sorted order (as in the spec)
        B.DEFAULT
        B.DEFAULT
        B.DEFAULT

        B.TERMINATOR
      ]

      endeo = build unstring:denyingUnstring

      creator = -> a:1, b:2, c:3

      spec = endeo.add creator

      class Thing
        constructor: (@a = 1, @b = 2, @c = 3) ->

      spec.imprint Thing.prototype

      thing = new Thing

      result = endeo[method] thing

      assert result, 'should have a result'
      buffer = result.buffer

      assert.equal Buffer.isBuffer(buffer), true, 'should have a buffer'
      # showBuffers buffer, answer
      assert.deepEqual buffer, answer


    it 'should encode a spec\'d class instance via ' + method, ->

      answer = Buffer.from [
        0 # object spec id is zero so it's the first byte.

        # these are in sorted order (as in the spec)
        4
        5
        6

        B.TERMINATOR
      ]

      endeo = build unstring:denyingUnstring

      creator = -> a:1, b:2, c:3

      spec = endeo.add creator

      class Thing
        constructor: (@a = 1, @b = 2, @c = 3) ->

      spec.imprint Thing.prototype

      thing = new Thing 4, 5, 6

      result = endeo[method] thing

      assert result, 'should have a result'
      buffer = result.buffer

      assert.equal Buffer.isBuffer(buffer), true, 'should have a buffer'
      # showBuffers buffer, answer
      assert.deepEqual buffer, answer



  it 'should write to a stream via encoder', (done) ->

    answer = Buffer.from [
      B.OBJECT
      B.STRING, 1, 0x61
      1
      B.STRING, 1, 0x62
      2
      B.STRING, 1, 0x63
      3
      B.TERMINATOR
    ]

    endeo = build unstring:denyingUnstring

    transform = endeo.encoder()

    transform.on 'finish', done
    transform.on 'error', done
    transform.on 'data', (buffer) -> assert.deepEqual buffer, answer

    transform.end a:1, b:2, c:3
