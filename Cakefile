fs     = require 'fs'
path   = require 'path'
{exec} = require 'child_process'

# Make sure we have our dependencies
try
  colors = require 'colors'
  wrench = require 'wrench'
catch error
  console.error 'Please run `npm install` first'
  process.exit 1

# Setup directory paths
paths =
  tmp_dir: '.tmp'
for dir in ['build', 'src', 'lib', 'test']
  paths["#{dir}_dir"] = dir
paths.closure_dir = path.join paths.lib_dir, 'closure'
paths.externs_dir = path.join paths.lib_dir, 'externs'
paths.calcdeps = path.join paths.closure_dir, 'library/bin/calcdeps.py'
paths.closure_builder = path.join paths.closure_dir, 'library/bin/build/closurebuilder.py'
paths.deps_js = path.join paths.closure_dir, 'library/deps.js'

# Create directories if they do not already exist
for dir in [paths.build_dir, paths.tmp_dir, paths.externs_dir]
  fs.mkdirSync dir, '0755' if not path.existsSync dir

# Read in package.json
package_info = JSON.parse fs.readFileSync path.join __dirname, 'package.json'

closure_compiler_flags = [
  "--compilation_level=ADVANCED_OPTIMIZATIONS"
  "--language_in=ECMASCRIPT5_STRICT"
  "--output_wrapper='(function(){%output%}).call(window);'"
  "--jscomp_error=accessControls"
  "--jscomp_error=checkRegExp"
  "--jscomp_error=checkVars"
  "--jscomp_error=deprecated"
  "--jscomp_error=invalidCasts"
  "--jscomp_error=missingProperties"
  "--jscomp_error=undefinedVars"
  "--jscomp_error=visibility"
  "--jscomp_warning=fileoverviewTags"
  "--jscomp_warning=nonStandardJsDocs"
  "--jscomp_warning=strictModuleDepCheck"
  "--jscomp_warning=unknownDefines"
  "--warning_level=VERBOSE"
  "--summary_detail_level=3"
  # Add any custom variable definitions below, using same format
  "--define='goog.DEBUG=false'"
  "--define='#{package_info.name}.DEBUG=false'"
].map (flag) -> "--compiler_flags=\"#{flag}\""

task 'build', 'Compiles and minifies JavaScript file for production use', ->
  console.log "Compiling CoffeeScript".yellow
  exec "coffee --compile --bare --output #{paths.lib_dir} #{paths.src_dir}", (e, o, se) ->
    if e
      console.error "Error encountered while compiling CoffeeScript".red
      console.error se
      process.exit 1

    console.log "CoffeeScript Compiled".green

    # Compile
    console.log "Compiling with Closure Compiler".yellow
    # Add custom externs to compiler flags
    if path.existsSync paths.externs_dir
      (fs.readdirSync paths.externs_dir).forEach (f) ->
        closure_compiler_flags.push("--compiler_flags=\"--externs=#{path.join paths.externs_dir, f}\"")

    output_path = path.join paths.build_dir, "#{package_info.name}-#{package_info.version}.js"
    p = exec "#{paths.closure_builder}
            --root #{paths.lib_dir} --input #{path.join paths.lib_dir, 'main.js'}
            --output_mode=compiled
            --compiler_jar=#{path.join paths.closure_dir, 'compiler/compiler.jar'}
            #{closure_compiler_flags.join ' '} --output_file=#{output_path}"
    p.stderr.on 'data', console_log_streamer true, (line) ->
      # Strip out command name from messages
      if line.substr(0, paths.closure_builder.length) is paths.closure_builder
        return line.substr(paths.closure_builder.length + 2)
      return line

    p.on 'exit', (code) ->
      if code
        console.error "Error encountered while compiling".red
        process.exit 1

      console.log "Compiled and minified: " + output_path.green
      invoke 'size'

task 'watch', 'Automatically recompile CoffeeScript files to JavaScript', ->
  console.log "Watching coffee files for changes, press Control-C to quit".yellow
  p = exec "coffee --compile --bare --watch --output #{paths.lib_dir} #{paths.src_dir}"
  p.stderr.on 'data', (data) -> console.error strip_endline(data).red
  p.stdout.on 'data', (data) ->
    # Hacky way to find if something compiled successfully
    if /compiled src/.test data
      console.log strip_endline(data).green
      # Re-calculate deps.js
      update_deps_debounced()
    else
      console.error strip_endline(data).red
      # Add warning into code since watch window is in bg
      insert_js_error "CoffeeScript compilation error: #{data}"

task 'clean', 'Remove temporary and generated files', ->
  # Delete generated deps.js file
  if path.existsSync paths.deps_js
    fs.unlinkSync paths.deps_js
    console.log "Deleted #{paths.deps_js}".magenta

  for file in fs.readdirSync paths.lib_dir
    filepath = path.join paths.lib_dir, file
    # Skip special directories
    continue if filepath in [paths.externs_dir, paths.closure_dir]
    stats = fs.lstatSync filepath
    if stats.isDirectory()
      wrench.rmdirSyncRecursive filepath
      console.log "Removed #{filepath}".magenta
    else if /\.js$/.test filepath
      fs.unlinkSync filepath
      console.log "Removed #{filepath}".magenta

  # Remove build/ and .tmp/
  for dir in [paths.tmp_dir, paths.build_dir]
    continue if not path.existsSync dir
    wrench.rmdirSyncRecursive dir
    console.log "Removed #{dir}".magenta

task 'size', 'Report file size', ->
  return if not path.existsSync paths.build_dir
  for file in fs.readdirSync paths.build_dir
    # Skip non-JS files
    if /\.js$/.test file
      stats = fs.statSync path.join paths.build_dir, file
      console.log "#{file}: #{stats.size} bytes"

# Helper for stripping trailing endline when outputting
strip_endline = (str) ->
  return str.slice(0, str.length - 1) if str[str.length - 1] is "\n"
  return str

# Helper for inserting error text into the main.js file
insert_js_error = (js) ->
  main_js = fs.openSync((path.join paths.lib_dir, 'main.js'), 'w')
  fs.writeSync main_js, """console.error(unescape("#{escape js}"))""" + "\n"
  fs.closeSync main_js

# Helper for updating deps.js file after changes
update_deps = ->
  # Write file out to same directory as base.js to take advantage of default
  # path
  exec "#{paths.calcdeps} -p #{paths.lib_dir} -o deps -e #{paths.deps_js}
        -e #{paths.externs_dir} --output_file=#{paths.deps_js}", (e, o, se) ->
    if e
      console.error "Error while computing deps.js".red
      console.error strip_endline se
    else
      console.log "Updated #{paths.deps_js}".green

update_deps_timeout = false
# Delay a little in case of multiple files modified
update_deps_debounced = ->
  clearTimeout update_deps_timeout if update_deps_timeout
  update_deps_timeout = setTimeout update_deps, 50

console_log_streamer = (useError, filter) ->
  buffer = ''
  return (str) ->
    buffer += str
    if str.indexOf("\n") isnt -1
      if filter
        buffer = filter buffer
      console[if useError then 'error' else 'log'] strip_endline buffer
      # Clear buffer
      buffer = ''
