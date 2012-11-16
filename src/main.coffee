###
main.coffee - Primary entry point
###

# Include other files
define ['./debug', './helpers'], (debug, helpers) ->
  # Console aliased to debug object, which is then stripped for production (see
  # `debug.js`)
  debug.info 'Running in DEBUG'
  return
