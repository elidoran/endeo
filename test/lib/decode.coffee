assert = require 'assert'
flatten = require '@flatten/array'

B = require '@endeo/bytes'
buildUnstring = require 'unstring'

build = require '../../lib/index.coffee'


describe 'test decode', ->

  it 'should build', -> assert build()

  it 'should build an input', ->

    endeo = build()
    buf = Buffer.from [1,2,3,4]
    input = endeo.input buf, 3

    assert.equal input.index, 3
    assert.equal input.buffer.length, 4
    assert.equal input.buffer, buf


  it 'should error for invalid byte to destring()', ->
    endeo = build()
    result = endeo.destring Buffer.from([B.ARRAY]), 0
    assert result?.error

  it 'should error for invalid byte to dearray()', ->
    endeo = build()
    result = endeo.dearray Buffer.from([B.STRING]), 0
    assert result?.error

  it 'should error for invalid byte to despecial()', ->
    endeo = build()
    result = endeo.despecial Buffer.from([B.ARRAY]), 0
    assert result?.error

  it 'should error for invalid byte to deobject()', ->
    endeo = build()
    result = endeo.deobject Buffer.from([B.ARRAY]), 0
    assert result?.error

  it 'should error for invalid byte to decode()', ->
    endeo = build()
    result = endeo.decode Buffer.from([B.TERMINATOR]), 0
    assert result?.error


  [ 'destring', 'decode' ].forEach (method) ->

    it 'should decode a string via ' + method, ->

      endeo = build()
      buf = Buffer.concat [
        Buffer.from [ B.STRING, 4 ]
        Buffer.from 'test'
      ]

      result = endeo[method] buf, 0

      assert result
      assert.equal result, 'test'


  [ 'dearray', 'decode' ].forEach (method) ->

    it 'should decode an array via ' + method, ->

      endeo = build()
      buf = Buffer.from [ B.ARRAY, 1, 2, 3, 4, 5, B.TERMINATOR ]

      result = endeo[method] buf, 0

      assert result
      assert.deepEqual result, [ 1, 2, 3, 4, 5 ]


  [ 'despecial', 'deobject', 'decode' ].forEach (method) ->

    it 'should decode a special object via ' + method, ->

      endeo = build()

      creator = -> one: null, two: null, array: null

      spec = endeo.add creator # no enhancers or imprint target

      buf = Buffer.concat [
        Buffer.from [ 0, B.ARRAY, 1, 2, 3, B.STRING, 6 ]
        Buffer.from 'string'
        Buffer.from [ B.SUB_TERMINATOR, 1, 22, B.TERMINATOR ]
      ]

      result = endeo[method] buf, 0

      assert result
      assert.deepEqual result, one:1, two:22, array: [ 1, 2, 3, 'string' ]


  [ 'despecial', 'deobject', 'decode' ].forEach (method) ->

    it 'should decode a special object with extended ID via ' + method, ->

      endeo = build()

      creator = -> one: null, two: null, array: null

      spec = endeo.add creator # no enhancers or imprint target
      # set it in there with an ID high enough to require int()
      endeo.specs[B.SPECIAL + 1] = endeo.specs[0]
      endeo.specs[0] = null
      spec.id = B.SPECIAL + 1

      buf = Buffer.concat [
        Buffer.from [ B.SPECIAL, B.P1, 150, B.ARRAY, 1, 2, 3, B.STRING, 6 ]
        Buffer.from 'string'
        Buffer.from [ B.SUB_TERMINATOR, 1, 22, B.TERMINATOR ]
      ]

      result = endeo[method] buf, 0

      assert result
      assert.deepEqual result, one:1, two:22, array: [ 1, 2, 3, 'string' ]


  [ 'deobject', 'decode' ].forEach (method) ->

    it 'should decode an object via ' + method, ->

      endeo = build()
      buf = Buffer.concat [
        Buffer.from [ B.OBJECT ]
        Buffer.from([ B.STRING, 1, 97, 1 ])
        Buffer.from([ B.STRING, 1, 98, 2 ])
        Buffer.from([ B.STRING, 1, 99, 3 ])
        Buffer.from [ B.TERMINATOR ]
      ]

      result = endeo[method] buf, 0

      assert result
      assert.deepEqual result, a: 1, b: 2, c: 3
