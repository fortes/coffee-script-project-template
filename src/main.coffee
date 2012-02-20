###
main.coffee - Primary entry point
###

# Make sure this matches up with your project namespace in package.json
goog.provide "myproject"

# Include other files
goog.require "myproject.helpers"

# Constants that can be overriden at compile time
###* @define {boolean} ###
myproject.DEBUG = true
###* @define {number} ###
myproject.SAMPLE_VALUE = 100

# This code gets completely stripped out when compiled and minified
if myproject.DEBUG
  window.console.info 'Running in DEBUG'

# Closure Compiler renames functions, if you want to expose a function for
# others to use, use goog.exportSymbol
goog.exportSymbol 'myproject.add', myproject.helpers.add
goog.exportSymbol 'myproject.square', myproject.helpers.square

# Unused or unreferenced functions are stripped when compiled. Since the
# multiply function was not used, it will not appear in the minified code

# Set the background to a light blue
document.documentElement.style.background = "#cef"
