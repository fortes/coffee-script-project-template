fs     = require 'fs'
path   = require 'path'
{exec} = require 'child_process'

# Make sure we have our dependencies
try
  colors     = require 'colors'
  wrench     = require 'wrench'
  coffeelint = require 'coffeelint'
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
paths.testLibDir = paths.testDir + '/lib'

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
  "--define='myproject.DEBUG=false'"
].map (flag) -> "--compiler_flags=\"#{flag}\""

coffeeLintConfig =
  no_tabs:
    level: 'error'
  no_trailing_whitespace:
    level: 'error'
  max_line_length:
    value: 80
    level: 'error'
  camel_case_classes:
    level: 'error'
  indentation:
    value: 2
    level: 'error'
  no_implicit_braces:
    level: 'ignore'
  no_trailing_semicolons:
    level: 'error'
  no_plusplus:
    level: 'ignore'
  no_throwing_strings:
    level: 'error'
  no_backticks:
    level: 'warn'
  line_endings:
    value: 'unix'
    level: 'warn'

task 'build', 'Compiles and minifies JavaScript file for production use', ->
  console.log "Compiling CoffeeScript".yellow
  # Compile test scripts for consistency
  exec "coffee --compile --bare --output #{paths.testLibDir} #{paths.testDir}"
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
    p.stderr.on 'data', stdErrorStreamer (line) ->
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
  srcWatcher  = exec "coffee --compile --bare --watch --output #{paths.libDir} #{paths.srcDir}"
  srcWatcher.stderr.on 'data', (data) -> console.error stripEndline(data).red
  srcWatcher.stdout.on 'data', (data) ->
    # Hacky way to find if something compiled successfully
    if /compiled src/.test data
      process.stdout.write data.green
      # Re-calculate deps.js
      updateDepsDebounced()
    else
      process.stderr.write data.red
      filenameMatch = data.match /^In src\/(.*)\.coffee/
      if filenameMatch and filenameMatch[1]
        # Add warning into code since watch window is in bg
        insertJsError filenameMatch[1], "CoffeeScript compilation error: #{data}"

  testWatcher = exec "coffee --compile --bare --watch --output #{paths.testLibDir} #{paths.testDir}"
  testWatcher.stderr.on 'data', stdErrorStreamer()
  testWatcher.stdout.on 'data', (data) ->
    if /compiled/.test data
      process.stdout.write data.green
    else
      process.stderr.write data.red

task 'lint', 'Check CoffeeScript for lint', ->
  console.log "Checking *.coffee for lint".yellow
  pass = "✔".green
  warn = "⚠".yellow
  fail = "✖".red
  getSourceFilePaths().forEach (filepath) ->
    fs.readFile filepath, (err, data) ->
      shortPath = filepath.substr paths.srcDir.length + 1
      result = coffeelint.lint data.toString(), coffeeLintConfig
      if result.length
        hasError = result.some (res) -> res.level is 'error'
        level = if hasError then fail else warn
        console.error "#{level}  #{shortPath}".red
        for res in result
          level = if res.level is 'error' then fail else warn
          console.error "   #{level}  Line #{res.lineNumber}: #{res.message}"
      else
        console.log "#{pass}  #{shortPath}".green

# Helper for finding all source files
getSourceFilePaths = (dirPath = paths.srcDir) ->
  files = []
  for file in fs.readdirSync dirPath
    filepath = path.join dirPath, file
    stats = fs.lstatSync filepath
    if stats.isDirectory()
      files = files.concat getSourceFilePaths filepath
    else if /\.coffee$/.test file
      files.push filepath
  files

task 'server', 'Start a web server in the root directory', ->
  console.log "Starting web server at http://localhost:8000"
  proc = exec "python -m SimpleHTTPServer"
  proc.stderr.on 'data', stdOutStreamer (data) -> data.grey
  proc.stdout.on 'data', stdOutStreamer (data) -> data.grey

task 'test:phantom', 'Run tests via phantomJS', ->
  exec "which phantomjs", (e, o, se) ->
    if e
      console.error "Must install PhantomJS http://phantomjs.org/".red
      process.exit -1

  # Disable web security so we don't have to run a server on localhost for AJAX
  # calls
  console.log "Running unit tests via PhantomJS".yellow
  p = exec "phantomjs #{paths.testLibDir}/phantom-driver.coffee --web-security=no"
  p.stderr.on 'data', stdErrorStreamer (data) -> data.red
  # The phantom driver outputs JSON
  p.stdout.on 'data', (data) ->
    unless /^PHANTOM/.test data
      process.stdout.write data.grey
      return

    pass = "✔".green
    fail = "✖".red

    # Split lines
    for line in (data.split '\n')
      continue unless line
      try
        obj = JSON.parse(line.substr 9)
        switch obj.name
          when 'log'
            continue if obj.result.result
            if 'expected' of obj.result
              console.error "#{fail}  Failure: #{obj.result.message}; Expected: #{obj.result.expected}, Actual: #{obj.result.actual}"
            else
              console.error "#{fail}  Failure: #{obj.result.message}"

          when 'moduleDone'
            if obj.result.failed
              console.error "#{fail}  #{obj.result.name} module: #{obj.result.passed} tests passed, " + "#{obj.result.failed} tests failed".red
            else
              console.log "#{pass}  #{obj.result.name} module: #{obj.result.total} tests passed"

          # Output statistics on completion
          when 'done'
            console.log "\nFinished in #{obj.result.runtime/1000}s".grey
            if obj.result.failed
              console.error "#{fail}  #{obj.result.passed} tests passed, #{obj.result.failed} tests failed (#{Math.round(obj.result.passed / obj.result.total * 100)}%)"
              process.exit -1
            else
              console.log "#{pass}  #{obj.result.total} tests passed"
      catch ex
        console.error "JSON parsing fail: #{line}".red

  p.on 'exit', (code) ->
    process.exit code


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

  # Remove generated test jS
  for file in fs.readdirSync paths.testLibDir
    continue unless /\.js$/.test file
    filepath = path.join paths.testLibDir, file
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

# Helper for inserting error text into a given file
insertJsError = (filename, js) ->
  jsFile = fs.openSync((path.join paths.libDir, "#{filename}.js"), 'w')
  fs.writeSync jsFile, """console.error(unescape("#{escape js}"))""" + "\n"
  fs.closeSync jsFile

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

stdOutStreamer = (filter) ->
  (str) ->
    str = filter str if filter
    process.stderr.write str

stdErrorStreamer = (filter) ->
  (str) ->
    str = filter str if filter
    process.stderr.write str.red
