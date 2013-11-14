#!/usr/bin/env node
/*!
* urequire - version 0.6.7
* Compiled on 2013-11-14
* git://github.com/anodynos/urequire
* Copyright(c) 2013 Agelos Pikoulas (agelos.pikoulas@gmail.com )
* Licensed MIT http://www.opensource.org/licenses/mit-license.php
*/
var VERSION = '0.6.7'; //injected by grunt:concat
// Generated by CoffeeScript 1.6.3
var Build, BundleBuilder, CMDOPTIONS, bundleBuilder, config, fs, l, tmplt, toArray, upath, urequireCommander, wrench, _, _B, _fn, _i, _len, _ref, _ref1;

_ = require('lodash');

fs = require('fs');

wrench = require("wrench");

_B = require('uberscore');

l = new _B.Logger('urequire/urequireCMD');

urequireCommander = require('commander');

upath = require('./paths/upath');

Build = require('./process/Build');

toArray = function(val) {
  return _.map(val.split(','), function(v) {
    if (_.isString(v)) {
      return v.trim();
    } else {
      return v;
    }
  });
};

config = {};

urequireCommander.version(VERSION).option('-o, --dstPath <dstPath>', 'Output converted files onto this directory').option('-f, --forceOverwriteSources', 'Overwrite *source* files (-o not needed & ignored)', void 0).option('-v, --verbose', 'Print module processing information', void 0).option('-d, --debugLevel <debugLevel>', 'Pring debug information (0-100)', void 0).option('-n, --noExports', 'Ignore all web `rootExports` in module definitions', void 0).option('-r, --webRootMap <webRootMap>', "Where to map `/` when running in node. On RequireJS its http-server's root. Can be absolute or relative to bundle. Defaults to bundle.", void 0).option('-s, --scanAllow', "By default, ALL require('') deps appear on []. to prevent RequireJS to scan @ runtime. With --s you can allow `require('')` scan @ runtime, for source modules that have no [] deps (eg nodejs source modules).", void 0).option('-a, --allNodeRequires', 'Pre-require all deps on node, even if they arent mapped to parameters, just like in AMD deps []. Preserves same loading order, but a possible slower starting up. They are cached nevertheless, so you might gain speed later.', void 0).option('-t, --template <template>', 'Template (AMD, UMD, nodejs), to override a `configFile` setting. Should use ONLY with `config`', void 0).option('-O, --optimize', 'Pass through uglify2 while saving/optimizing - currently works only for `combined` template, using r.js/almond.', void 0).option('-C, --continue', 'Dont bail out while processing (module processing/conversion errors)', void 0).option('-w, --watch', "Watch for file changes in `bundle.path` & reprocess them. Note: new dirs are ignored", void 0).option('-b, --bare', "Don't enclose AMD/UMD modules in Immediate Function Invocation (safety wraper).", void 0).option('-f, --filez', "NOT IMPLEMENTED (in CLI - use a config file or grunt-urequire). Process only modules/files in filters - comma seprated list/Array of Strings or Regexp's", toArray).option('-j, --jsonOnly', 'NOT IMPLEMENTED. Output everything on stdout using json only. Usefull if you are building build tools', void 0).option('-e, --verifyExternals', 'NOT IMPLEMENTED. Verify external dependencies exist on file system.', void 0);

_ref = Build.templates;
_fn = function(tmplt) {
  return urequireCommander.command("" + tmplt + " <path>").description("Converts all modules in <path> using '" + tmplt + "' template.").action(function(path) {
    config.template = tmplt;
    return config.path = path;
  });
};
for (_i = 0, _len = _ref.length; _i < _len; _i++) {
  tmplt = _ref[_i];
  _fn(tmplt);
}

urequireCommander.command('config <configFiles...>').action(function(cfgFiles) {
  return config.derive = toArray(cfgFiles);
});

urequireCommander.on('--help', function() {
  return l.log("Examples:\n                                                                                       \u001b[32m\n  $ urequire UMD path/to/amd/moduleBundle -o umd/moduleBundle                          \u001b[0m\n                  or                                                                   \u001b[32m\n  $ urequire AMD path/to/moduleBundle -f                                               \u001b[0m\n                  or                                                                   \u001b[32m\n  $ urequire config path/to/configFile.json,anotherConfig.js,masterConfig.coffee -d 30 \u001b[0m\n\n*Notes: Command line values have precedence over configFiles;\n        Values on config files on the left have precedence over those on the right (deeply traversing).*\n\nModule files in your bundle can conform to the *standard AMD* format: \u001b[36m\n    // standard AMD module format - unnamed or named (not recommended by AMD)\n    define(['dep1', 'dep2'], function(dep1, dep2) {...});  \u001b[0m\n\nAlternativelly modules can use the *standard nodejs/CommonJs* format: \u001b[36m\n    var dep1 = require('dep1');\n    var dep2 = require('dep2');\n    ...\n    module.exports = {my: 'module'} \u001b[0m\n\nFinally, a 'relaxed' format can be used (combination of AMD+commonJs), along with asynch requires, requirejs plugins, rootExports + noConflict boilerplate, exports.bundle and much more - see the docs. \u001b[36m\n    // uRequire 'relaxed' modules format\n  - define(['dep1', 'dep2'], function(dep1, dep2) {\n      ...\n      // nodejs-style requires, with no side effects\n      dep3 = require('dep3');\n      ....\n      // asynchronous AMD-style requires work in nodejs\n      require(['someDep', 'another/dep'], function(someDep, anotherDep){...});\n\n      // RequireJS plugins work on web + nodejs\n      myJson = require('json!ican/load/requirejs/plugins/myJson.json');\n      ....\n      return {my: 'module'};\n    }); \u001b[0m\n\nNotes:\n  --forceOverwriteSources (-f) is useful if your sources are not `real sources`  eg. you use coffeescript :-).\n    WARNING: -f ignores --dstPath\n\n  - Your source can be coffeescript (more will follow) - .coffee files are internally translated to js.\n\n  - configFiles can be written as a .js module, .coffee module, json and much more - see 'butter-require'\n\n  uRequire version " + VERSION);
});

urequireCommander.parse(process.argv);

CMDOPTIONS = _.map(urequireCommander.options, function(o) {
  return o.long.slice(2);
});

_.extend(config, _.pick(urequireCommander, CMDOPTIONS));

delete config.version;

if (_.isEmpty(config)) {
  l.er("No CMD options or config file specified.\nNot looking for any default config file in this uRequire version.\nType -h if U R after help!\"");
  l.log("uRequire version " + VERSION);
} else {
  if (config.debugLevel != null) {
    _B.Logger.addDebugPathLevel('urequire', config.debugLevel * 1);
  }
  if (config.verbose) {
    l.verbose('uRequireCmd called with cmdConfig=\n', config);
  }
  config.done = function(doneValue) {
    var b, _ref1, _ref2;
    b = {
      startDate: (typeof bundleBuilder !== "undefined" && bundleBuilder !== null ? (_ref1 = bundleBuilder.build) != null ? _ref1.startDate : void 0 : void 0) || new Date(),
      count: (typeof bundleBuilder !== "undefined" && bundleBuilder !== null ? (_ref2 = bundleBuilder.build) != null ? _ref2.count : void 0 : void 0) || 0
    };
    if ((doneValue === true) || (doneValue === void 0)) {
      return l.verbose("uRequireCmd done() #" + b.count + " successfully in " + ((new Date() - b.startDate) / 1000) + "secs.");
    } else {
      return l.er("uRequireCmd done() #" + b.count + " with errors in " + ((new Date() - b.startDate) / 1000) + "secs.");
    }
  };
  BundleBuilder = require('./urequire').BundleBuilder;
  bundleBuilder = new BundleBuilder([config]);
  bundleBuilder.buildBundle();
  if (bundleBuilder != null ? (_ref1 = bundleBuilder.build) != null ? _ref1.watch : void 0 : void 0) {
    bundleBuilder.watch();
  }
}
