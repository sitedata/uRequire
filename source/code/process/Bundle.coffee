# external
_ = require 'lodash'
_.mixin (require 'underscore.string').exports()
_B = require 'uberscore'
_fs = require 'fs'
_wrench = require 'wrench'

# uRequire
Logger = require '../utils/Logger'
l = new Logger 'Bundle'

upath = require '../paths/upath'
getFiles = require "./../utils/getFiles"
uRequireConfigMasterDefaults = require '../config/uRequireConfigMasterDefaults'
DependenciesReporter = require './../DependenciesReporter'
UModule = require './UModule'

###

###
class Bundle
  Function::property = (p)-> Object.defineProperty @::, n, d for n, d of p
  Function::staticProperty = (p)=> Object.defineProperty @::, n, d for n, d of p
  constructor:-> @_constructor.apply @, arguments

  interestingDepTypes: ['notFoundInBundle', 'untrustedRequireDependencies', 'untrustedAsyncDependencies']

  @staticProperty requirejs: get:=> require 'requirejs'

  _constructor: (bundleCfg)->
    # clone all bundleCfg properties to @
    _.extend @, _B.deepCloneDefaults bundleCfg, uRequireConfigMasterDefaults.bundle

    @main or= 'main' # @todo: add implicit bundleName, or index.js, main.js & other sensible defaults
    @uModules = {}
    @reporter = new DependenciesReporter @interestingDepTypes #(if build.verbose then null else @interestingDepTypes)
    @loadModules()


  ###
  Read / refresh all files in directory.
  Not run everytime there is a file added/removed, unless we need to:
  Runs initially and in unkonwn -watch / refresh situations
  ###
  @property moduleFilenames: get: ->
    try
      @filenames =  getFiles @bundlePath # get all filenames each time we 'refresh'

      moduleFilenames =  getFiles @bundlePath, (mfn)=>
        _B.inFilters(mfn, @includes) and not _B.inFilters(mfn, @excludes) #@todo (uberscore):notFilters()

      # @todo: cleanup begone modules
      #@deleteModules _.difference(_.keys(@uModules), moduleFilenames)
    catch err
      err.uRequire = "*uRequire #{@VERSION}*: Something went wrong reading from '#{@bundlePath}'."
      l.err err.uRequire
      throw err

    l.verbose 'Bundle files found (*.*):\n', @filenames,
              '\nModule files found (js, coffee etc):\n', moduleFilenames
    moduleFilenames

  deleteModules: (modules)->
    delete @uModules[m] for m in modules if @uModules[m]

  ###
    Processes each module, as instructed by `watcher` in a [] paramor read file system (@moduleFilenames)
    @param build - see `config/uRequireConfigMasterDefaults.coffee`
    @param String or []<String> with filenames to process.
      @default read files from filesystem (property @moduleFilenames)
  ###
  loadModules: (moduleFilenames = @moduleFilenames)->
    for moduleFN in _B.arrayize moduleFilenames
      try
        moduleSource = _fs.readFileSync "#{@bundlePath}/#{moduleFN}", 'utf-8'

        # check exists & source up to date
        if @uModules[moduleFN]
          if uM.sourceCode isnt moduleSource
            delete @uModule[moduleFN]

        if not @uModules[moduleFN]
          @uModules[moduleFN] = new UModule @, moduleFN, moduleSource
      catch err
        l.err 'TEMP:' + err
        if not _fs.existsSync "#{@bundlePath}/#{moduleFN}" # remove it, if missing from filesystem
          l.log "Removed file : '#{@bundlePath}/#{moduleFN}'"
          delete @uModules[moduleFN] if @uModules[moduleFN]
        else
          err.uRequire = "*uRequire #{@VERSION}*: Something went wrong while processing '#{moduleFN}'."
          l.err err.uRequire
          throw err



  ###
  Globals dependencies & the variables they might bind with, througout the this bundle.

  The information is gathered from all modules and joined together.

  Also it uses bundle.dependencies.variableNames, for globals + varnames bindings.

  @return {dependencies.variableNames} globals & variable names, eg
              {
                  'underscore': '_'
                  'jquery': ["$", "jQuery"]
                  'models/PersonModel': ['persons', 'personsModel']
              }

  @todo: If there is a global that ends up with empty vars eg {myStupidGlobal:[]}
    (cause nodejs format was used and var names are NOT read there)
    Then myStupidGlobal MUST have a var name on the config.
    Otherwise, we should alert for fatal error & perhaps quit!

  @todo : refactor & generalize !
  ###

  @property globalDepsVars: get:->
    _globalDepsVars = {}

    gatherDepsVars = (depsVars)-> # add non-exixsting var to the dep's `vars` array
      for dep, vars of depsVars
        existingVars = (_globalDepsVars[dep] or= [])
        existingVars.push v for v in (_B.arrayize vars) when v not in existingVars

    for uMK, uModule of @uModules
      gatherDepsVars uModule.globalDepsVars

    if variableNames = @dependencies?.variableNames
      l.warn '_globalDepsVars=\n', _globalDepsVars
      # pick only for existing GLOBALS, that have no vars info discovered yet
      gg = _B.go variableNames, fltr:(v,k)-> _globalDepsVars[k] and _.isEmpty(_globalDepsVars[k])
      l.warn '\npicked variableNames=\n', gg
      gatherDepsVars gg

    _globalDepsVars

  ###
    @param { Object | []<String> } dependencyVariables see `bundle.dependencies.bundle`

    `['dep1', 'dep2']`

      or

    ```
    {
      'underscore': '_'
      'jquery': ["$", "jQuery"]
      'models/PersonModel': ['persons', 'personsModel']
    }
    ```
    These dependencies are added to this module, on all dep arrays + parameters

    @todo : FIX TO CATER FOR var exports format, discover variables names etc
    Must end up like this

    bundleExports: {
        'lodash': ['_', 'lodashleme']}
      }
  ###
  addDependencies: (dependencyVariables)->

    if _.isArray dependencyVariables
      depsVars = _.extend @bundle.globalDepsVars, @bundle.dependencies.variableNames # @todo: merge arrays, instead of overwritting
      for dep in dependencyVariables
        for varName in depsVars[dep]
          addDepVar dep, varName

    else
      if _.isObject dependencyVariables
        for dep, variables of dependencyVariables
          for varName in variables
            addDepVar dep, varName



  ###
  Build / convert all uModules that have changed since last build
  ###
  buildChangedModules: (build)->
    haveChanges = false

    for mfn, uModule of @uModules
      if not uModule.convertedJs # it has changed, then conversion is needed :-)
        haveChanges = true
        #@todo: reset reporter!


        convertedJS = uModule.convert build # @todo change this

        # Now, it is send to build.out() or saved to build.outputPath

        # but first, decide where to output when combining
        if build.template is 'combine' #todo: read properly
          if not build.combinedFile # change build's paths
            build.combinedFile = upath.changeExt build.outputPath, '.js'
            build.outputPath = "#{build.combinedFile}__temp"
          #@interestingDepTypes.push 'global' #@todo: add to this reporter's run !

        if _.isFunction build.out
          build.out uModule.modulePath, convertedJS

    @combine build if build.template is 'combine' and haveChanges

    if not _.isEmpty(@reporter.reportData)
      l.log '\n########### urequire, final report ########### :\n', @reporter.getReport()

  #Bundle::build.debugLevel = 10 # @todo: try this for debugin'


  ###
  ###
  combine: (build)->
    almondTemplates = new (require '../templates/AlmondOptimizationTemplate') {
      @globalDepsVars
      @main
    }

    rjsConfig =
      paths: almondTemplates.paths
      wrap: almondTemplates.wrap
      baseUrl: build.outputPath
      include: @main
      out: build.combinedFile
#      out: (text)=>
#        #todo: build.out it!
#        l.verbose "uRequire: writting combinedFile '#{combinedFile}'."
#        @outputToFile text, @combinedFile
#        if _fs.existsSync @combinedFile
#          l.verbose "uRequire: combined file '#{combinedFile}' written successfully."

      optimize: "none" #  uglify: {beautify: true, no_mangle: true} ,
      name: 'almond'

    for fileName, genCode of almondTemplates.dependencyFiles
      build.outputToFile "#{build.outputPath}/#{fileName}.js", genCode

    try # copy almond.js from GLOBAL/urequire/node_modules -> outputPath #@todo : alternative paths ?
      build.outputToFile(
        "#{build.outputPath}/almond.js"
        _fs.readFileSync("#{__dirname}/../../../node_modules/almond/almond.js", 'utf-8')
      )
    catch err
      err.uRequire = """
        uRequire: error copying almond.js from uRequire's installation node_modules - is it installed ?
        Tried here: '#{__dirname}/../../../node_modules/almond/almond.js'
      """
      l.err err.uRequire
      throw err

    try
      _fs.unlinkSync @combinedFile
    catch err #todo : handle it ?

    l.verbose "optimize with r.js with our kind of 'uRequire.build.js' = ", JSON.stringify _.omit(rjsConfig, ['wrap']), null, ' '
    @requirejs.optimize rjsConfig, (buildResponse)->
      l.verbose 'r.js buildResponse = ', buildResponse
      if false # not build.watch @todo implement watch
        _wrench.rmdirSyncRecursive build.outputPath

      if _fs.existsSync @combinedFile
        l.verbose "uRequire: combined file '#{@combinedFile}' written successfully."


if Logger::debug.level > 90
  YADC = require('YouAreDaChef').YouAreDaChef

  YADC(Bundle)
    .before /_constructor/, (match, bundle, filename)->
      l.debug "Before '#{match}' with 'filename' = '#{filename}', bundle = \n", _.pick(bundle, [])
    .before /combine/, (match)->
      l.debug 'combine: optimizing with r.js'

module.exports = Bundle