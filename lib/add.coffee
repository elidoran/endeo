# Endeo's add() method.
# uses the `Specials` instance to build an "object spec" (Special)
module.exports = (creator, enhancers, proto) ->

  # process all and return an array of the spec's
  if Array.isArray creator then (@add each, enhancers for each in creator)

  # else add the one and return the spec
  else if typeof creator is 'function'
    # TODO: allow it to specify its own id as $id$...
    # TODO: tell `@debyte` the specs cuz it'll need them to decode.
    spec = @specs[@specs.length] = @specials.build @specs.length, creator, enhancers

    # if they gave us an object to imprint on then do it...
    if proto? then spec.imprint proto

    return spec

  # return error object
  else error: 'object spec must be a function, not a ' + typeof creator
