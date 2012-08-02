###
main.coffee - Primary entry point
###

# Make sure this matches up with your project namespace in package.json
goog.provide "myproject"

# Include other files
goog.require "debug"
goog.require "myproject.helpers"

# Constant that can be overriden at compile time (edit Cakefile)

###* @define {number} ###
myproject.SAMPLE_VALUE = 100

# This code gets completely stripped out when compiled and minified
if DEBUG
  window.myDebugValue = "Hello World"

# Console aliased to debug object, which is then stripped for production (see
# `debug.js`)
debug.info 'Running in DEBUG'

# Closure Compiler renames functions, if you want to expose a function for
# others to use, use goog.exportSymbol
goog.exportSymbol 'myproject.add', myproject.helpers.add
goog.exportSymbol 'myproject.square', myproject.helpers.square

# Unused or unreferenced functions are stripped when compiled. Since the
# multiply function was not used, it will not appear in the minified code
