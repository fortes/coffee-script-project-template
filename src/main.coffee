###
main.coffee - Primary entry point
###

# Include other files
debug = require './debug'
helpers = require './helpers'

# Console aliased to debug object, which is then stripped for production (see
# `debug.js`)
debug.info 'Running in DEBUG'

window.alert helpers.add 2, 2
