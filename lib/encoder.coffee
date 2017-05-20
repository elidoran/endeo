# this function creates an encoding Transform
{Transform} = require 'stream'

# Endeo class's encoder() function
module.exports = (options) ->

  # use to ref `endeo` in the transform() function
  endeo = this

  # built after the Transform and used for endeo._encode()
  output = null

  transform = new Transform

    # can give it objects to encode
    writableObjectMode: true

    # it sends forward Buffer's (not objects)
    readableObjectMode: false

    # allow only 10 objects before worrying
    # TODO: allow this to be configurable via constructor options.
    highWaterMark: options?.highWaterMark ? 10

    transform: (object, _, next) ->

      # encode into the same `output` to push() results.
      result = endeo._encode object, output

      # pass an error if it exists.
      next result.error

  # now that we have the Transform instance we can create `output`.
  output = @output transform.push, transform

  return transform
