###
main.coffee - Primary entry point
###

# Make sure this matches up with your project namespace in the Cakefile
goog.provide "myproject"

# Constants that can be overriden at compile time
###* @define {boolean} ###
myproject.DEBUG = true
###* @define {number} ###
myproject.SAMPLE_VALUE = 100

# This code gets completely stripped out when compiled and minified
if myproject.DEBUG
  window.console.info 'Running in DEBUG'

window.hello = 'world'
