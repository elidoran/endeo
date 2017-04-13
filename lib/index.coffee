enbyte  = require 'enbyte'
debyte  = require 'debyte'
debytes = require 'debytes'

class Endeo

  constructor: () ->

  add: (creator) ->

    # TODO: may be an array of them

  # TODO: remove() ?

  encode: (object, writer, target) ->

  decode: (buffer, done) ->


# export a function which creates an instance
module.exports = (options) -> new Endeo options

# export the class as a sub property on the function
module.exports.Endeo = Endeo
