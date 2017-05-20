class Endeo

  constructor: require './constructor'

  add: require './add'

  # TODO: export an endeo instance to import later.
  # import : require './import'
  # export : require './export'

  # NOTE:
  #   used by the encoder()
  #   writer/target are likely:
  #   Writable/write or Transform/push.
  output: (writer, target) -> @Output {writer, target}

  input : (buffer, index) -> @Input buffer, index


  # generic entry point for encoding anything.
  # NOTE: when type is known ahead of time use specific ones.
  encode: (thing) -> @_encode thing, @Output()

  _encode: (thing, output) ->

    switch typeof thing

      when 'object'

        if Array.isArray thing then @_array thing, output

        else @_object thing, output

      when 'string' then @_string thing, output

      # when 'function' then @fn thing

      else error: 'not an object, array, or string', value: thing


  # specific ones skip the "typeof" check to get here...
  object: (object) -> @_object object, @Output()

  _object: (object, output) ->

    # we don't need to send B.SPECIAL first, we can skip it
    # on the top-level chunk.
    output.consumeMarkerIf @B.SPECIAL
    @enbyte.object object, output
    output.marker @B.TERMINATOR
    output.complete()

  special: (object) -> @_special object, @Output()

  _special: (object, output) ->

    # we don't need to send B.SPECIAL first, we can skip it
    # on the top-level chunk.
    output.consumeMarkerIf @B.SPECIAL
    @enbyte.special object.$ENDEO_SPECIAL, object, output
    output.marker @B.TERMINATOR
    output.complete()


  array: (array) -> @_array array, @Output()

  _array: (array, output) ->

    if array.length > 0 then @enbyte.array array, output
    else output.marker @B.ARRAY
    output.marker @B.TERMINATOR
    output.complete()


  string: (string) -> @_string string, @Output()

  _string: (string, output) ->

    output.marker @B.STRING
    if string.length > 0 then @enbyte.string string, output
    output.marker @B.TERMINATOR
    output.complete()


  # top-level most generic entry point. creates an input.
  decode: (buffer, index) -> @_decode @Input(buffer, index)

  # inner entry point when we already have an input.
  _decode: (input) ->

    byte = input.byte()

    # if it's in the range meaning it's an "object spec" ID
    if byte < @B.SPECIAL then @debyte._special byte, input

    else switch byte

      when @B.OBJECT  then @debyte._generic input
      when @B.ARRAY   then @debyte._array input
      when @B.STRING  then @debyte._string input
      when @B.SPECIAL then @debyte._special @debyte.int(input), input

      else error: 'invalid indicator byte', byte: byte


  # top-level entry point to decode an object
  deobject: (buffer, index) -> @_deobject @Input buffer, index

  _deobject: (input) ->

    byte = input.byte()

    # if it's in the range meaning it's an "object spec" ID
    if byte < @B.SPECIAL then @debyte._special byte, input

    else switch byte

      when @B.OBJECT  then @debyte._generic input
      when @B.SPECIAL then @debyte._special @debyte.int(input), input

      else error: 'buffer must start with an object indicator', input: input


  # top-level entry point to decode a "special" object
  despecial: (buffer, index) -> @_despecial @Input buffer, index

  _despecial: (input) ->

    byte = input.byte()

    if byte < @B.SPECIAL       then @debyte._special byte, input

    else if byte is @B.SPECIAL then @debyte._special @debyte.int(input), input

    else error: 'buffer should start with a special object id', input: input


  # top-level entry point to decode an array
  dearray: (buffer, index) -> @_dearray @Input buffer, index

  _dearray: (input) ->

    byte = input.byte()

    if byte is @B.ARRAY then @debyte._array input

    else error: 'buffer should start with an array marker byte', input: input



  # top-level entry point to decode a string
  destring: (buffer, index) -> @_destring @Input buffer, index

  _destring: (input) ->

    if input.byte() is @B.STRING then @debyte._string input

    else error: 'buffer should start with a string marker byte', input: input



# export a function which creates an instance
module.exports = (options) -> new Endeo options

# export the class as a sub property on the function
module.exports.Endeo = Endeo
