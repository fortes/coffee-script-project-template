# CoffeeScript Project Template

Project template for client-side JavaScript projects written in CoffeeScript and compiled with Google's [Closure Compiler](http://code.google.com/closure/compiler/). Features include:

* Watch CoffeeScript files for changes and automatically compile to JavaScript
* Generate `deps.js` file so Closure can manage script dependencies
* Output CoffeeScript compilation errors to browser while developing
* Compile scripts using Closure's Advanced Compilation mode

## Pre-requisites

1. Node.js, NPM, and CoffeeScript
2. Java: For running the Closure compiler
3. Python: For running Closure build scripts

## Instructions

1. [Fork this repository](http://help.github.com/fork-a-repo/) and edit the name, etc on GitHub
2. Clone locally
3. Edit `package.json`
4. Run `npm install` to install local dependencies
5. Run `cake watch` to automatically compile CoffeeScript to JavaScript
6. Start coding
7. Run `cake build` to compile and minify your code with Closure Compiler

## Commands

* `cake build`: Compiles and minifies JavaScript file for production use
* `cake watch`: Automatically recompile CoffeeScript files to JavaScript
* `cake clean`: Remove temporary and generated files
* `cake size`: Report file size information for any scripts within `build/`

## Future Ideas

* Headless testing via PhantomJS
* Generate documentation

## Contributors

* [Filipe Fortes](http://www.fortes.com) ([@fortes](http://twitter.com/fortes))

## License

MIT
