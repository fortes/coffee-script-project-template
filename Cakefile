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
  tmpDir: '.tmp'
for dir in ['build', 'src', 'lib', 'test']
  paths["#{dir}Dir"] = dir
paths.closureDir = path.join paths.libDir, 'closure'
paths.externsDir = path.join paths.libDir, 'externs'
paths.calcdeps = path.join paths.closureDir, 'library/bin/calcdeps.py'
paths.closureBuilder = path.join paths.closureDir, 'library/bin/build/closurebuilder.py'
paths.depsJs = path.join paths.closureDir, 'library/deps.js'

# Create directories if they do not already exist
for dir in [paths.buildDir, paths.tmpDir, paths.externsDir]
  fs.mkdirSync dir, '0755' if not path.existsSync dir

# Read in package.json
packageInfo = JSON.parse fs.readFileSync path.join __dirname, 'package.json'

closureCompilerFlags = [
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
  "--define='DEBUG=false'"
].map (flag) -> "--compiler_flags=\"#{flag}\""

task 'build', 'Compiles and minifies JavaScript file for production use', ->
  console.log "Compiling CoffeeScript".yellow
  exec "coffee --compile --bare --output #{paths.libDir} #{paths.srcDir}", (e, o, se) ->
    if e
      console.error "Error encountered while compiling CoffeeScript".red
      console.error se
      process.exit 1

    console.log "CoffeeScript Compiled".green

    # Compile
    console.log "Compiling with Closure Compiler".yellow
    # Add custom externs to compiler flags
    if path.existsSync paths.externsDir
      (fs.readdirSync paths.externsDir).forEach (f) ->
        closureCompilerFlags.push("--compiler_flags=\"--externs=#{path.join paths.externsDir, f}\"")

    outputPath = path.join paths.buildDir, "#{packageInfo.name}-#{packageInfo.version}.js"
    p = exec "#{paths.closureBuilder}
            --root #{paths.libDir} --input #{path.join paths.libDir, 'main.js'}
            --output_mode=compiled
            --compiler_jar=#{path.join paths.closureDir, 'compiler/compiler.jar'}
            #{closureCompilerFlags.join ' '} --output_file=#{outputPath}"
    p.stderr.on 'data', consoleLogStreamer true, (line) ->
      str = line
      # Strip out command name from messages
      if line.substr(0, paths.closureBuilder.length) is paths.closureBuilder
        str = line.substr(paths.closureBuilder.length + 2)

      if /ERROR/.test str
        str = str.red
      else if /WARNING/.test str
        str = str.yellow
      else
        str = str.grey

      str

    p.on 'exit', (code) ->
      if code
        console.error "Error encountered while compiling".red
        process.exit 1

      console.log "Compiled and minified: " + outputPath.green
      invoke 'size'

task 'watch', 'Automatically recompile CoffeeScript files to JavaScript', ->
  console.log "Watching coffee files for changes, press Control-C to quit".yellow
  p = exec "coffee --compile --bare --watch --output #{paths.libDir} #{paths.srcDir}"
  p.stderr.on 'data', (data) -> console.error stripEndline(data).red
  p.stdout.on 'data', (data) ->
    # Hacky way to find if something compiled successfully
    if /compiled src/.test data
      console.log stripEndline(data).green
      # Re-calculate deps.js
      updateDepsDebounced()
    else
      console.error stripEndline(data).red
      # Add warning into code since watch window is in bg
      insertJsError "CoffeeScript compilation error: #{data}"

task 'clean', 'Remove temporary and generated files', ->
  # Delete generated deps.js file
  if path.existsSync paths.depsJs
    fs.unlinkSync paths.depsJs
    console.log "Deleted #{paths.depsJs}".magenta

  for file in fs.readdirSync paths.libDir
    filepath = path.join paths.libDir, file
    # Skip special directories
    continue if filepath in [paths.externsDir, paths.closureDir]
    stats = fs.lstatSync filepath
    if stats.isDirectory()
      wrench.rmdirSyncRecursive filepath
      console.log "Removed #{filepath}".magenta
    else if /\.js$/.test filepath
      fs.unlinkSync filepath
      console.log "Removed #{filepath}".magenta

  # Remove build/ and .tmp/
  for dir in [paths.tmpDir, paths.buildDir]
    continue if not path.existsSync dir
    wrench.rmdirSyncRecursive dir
    console.log "Removed #{dir}".magenta

task 'size', 'Report file size', ->
  return if not path.existsSync paths.buildDir
  for file in fs.readdirSync paths.buildDir
    # Skip non-JS files
    if /\.js$/.test file
      stats = fs.statSync path.join paths.buildDir, file
      console.log "#{file}: #{stats.size} bytes"

# Helper for stripping trailing endline when outputting
stripEndline = (str) ->
  return str.slice(0, str.length - 1) if str[str.length - 1] is "\n"
  return str

# Helper for inserting error text into the main.js file
insertJsError = (js) ->
  mainJs = fs.openSync((path.join paths.libDir, 'main.js'), 'w')
  fs.writeSync mainJs, """console.error(unescape("#{escape js}"))""" + "\n"
  fs.closeSync mainJs

# Helper for updating deps.js file after changes
updateDeps = ->
  # Write file out to same directory as base.js to take advantage of default
  # path
  exec "#{paths.calcdeps} -p #{paths.libDir} -o deps -e #{paths.depsJs}
        -e #{paths.externsDir} --output_file=#{paths.depsJs}", (e, o, se) ->
    if e
      console.error "Error while computing deps.js".red
      console.error stripEndline se
    else
      console.log "Updated #{paths.depsJs}".green

updateDepsTimeout = false
# Delay a little in case of multiple files modified
updateDepsDebounced = ->
  clearTimeout updateDepsTimeout if updateDepsTimeout
  updateDepsTimeout = setTimeout updateDeps, 50

consoleLogStreamer = (useError, filter) ->
  buffer = ''
  return (str) ->
    buffer += str
    if str.indexOf("\n") isnt -1
      if filter
        buffer = filter buffer
      process[if useError then 'stderr' else 'stdout'].write buffer
      # Clear buffer
      buffer = ''
