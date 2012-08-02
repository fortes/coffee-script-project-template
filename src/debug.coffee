###*
@fileoverview A debug-only wrapper around console functions
###

goog.provide 'debug'

###*
Gets set to `false` during build/minification.

Must use escaping to prevent CoffeeScript from moving the var declaration to the
top of the file, which breaks the Closure annotation
@define {boolean}
###
`var DEBUG = true`

# Escape CoffeeScript for variable assignment to prevent a `var` declaration
if DEBUG
  `debug = window.console`
else
  `debug = {}`
  # Map functions to no-op
  # Function list here: http://getfirebug.com/wiki/index.php/Console_API
  debug.log = ->
  debug.debug = ->
  debug.info = ->
  debug.warn = ->
  debug.error = ->
  debug.assert = ->
  debug.clear = ->
  debug.dir = ->
  debug.dirxml = ->
  debug.trace = ->
  debug.group = ->
  debug.groupCollapse = ->
  debug.groupEnd = ->
  debug.time = ->
  debug.timeEnd = ->
  debug.timeStamp = ->
  debug.profile = ->
  debug.profileEnd = ->
  debug.count = ->
  debug.exception = ->
  debug.table = ->
