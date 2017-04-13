assert = require 'assert'

buildEndeo = require '../../lib/index.coffee'

describe 'test endeo', ->

  it 'should build', -> assert buildEndeo()

  it 'should add an object serializer spec'

  it 'should encode an object'
  it 'should encode an array'
  it 'should encode a string'
  it 'should encode a nested object'

  it 'should decode an object'
  it 'should decode an array'
  it 'should decode a string'
  it 'should decode a nested object'
