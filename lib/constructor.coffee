# Endeo's constructor() method
module.exports = (options) ->

  opts = options ? {}

  # store Spec instances
  @specs = []

  # the Input/Output class/builder to use:
  # either one provided via options or default packages
  @Input  = opts.Input  ? require '@endeo/input'
  @Output = opts.Output ? require '@endeo/output'

  # use an unstring for string replacement management
  # either one provided via options or package `unstring`
  @unstring = opts.unstring ? require('unstring') strings:opts.strings

  # the only byte endeo needs to know. from options or the default.
  @B = opts.bytes ? require '@endeo/bytes'

  # use a Specials to build each "object spec" (Special).
  # either one provided via options or package `@endeo/special`.
  # also, provide option's `types` if we build one...
  @specials = opts.specials ? require('@endeo/specials') types:opts.types

  # use an enbyte to encode stuff.
  # either one provided via options or package `enbyte`
  @enbyte = opts.enbyte ? require('enbyte') { @unstring, bytes:@B }

  # use a debyte to decode stuff.
  # either one provided via options or package `debyte`
  @debyte = opts.debyte ? require('debyte') { @unstring, bytes:@B, @specs }

  # use an encoder to send encoded chunks via streaming
  @encoder = opts.encoder ? require('./encoder')

  # use a decoder to decode in chunks via streaming
  @decoder = opts.decoder ? require('@endeo/decoder') {
    bytes:@B, @specials, types: opts.types, @unstring, unstringOptions: opts.unstringOptions
  }

  # if specs were provided to the constructor then build them via spec()
  if opts.specs?.length > 0 then @add opts.specs

  return
