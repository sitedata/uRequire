/*!
* urequire - version 0.3.0beta1
* Compiled on 2013-05-11
* git://github.com/anodynos/urequire
* Copyright(c) 2013 Agelos Pikoulas (agelos.pikoulas@gmail.com )
* Licensed MIT http://www.opensource.org/licenses/mit-license.php
*/

var VERSION = '0.3.0beta1'; //injected by grunt:concat

// Generated by CoffeeScript 1.6.2
var Urequire;

(require('uberscore')).Logger.prototype.VERSION = typeof VERSION !== "undefined" && VERSION !== null ? VERSION : '{NO_VERSION}';

Urequire = (function() {
  function Urequire() {}

  Function.prototype.property = function(props) {
    var descr, name, _results;

    _results = [];
    for (name in props) {
      descr = props[name];
      _results.push(Object.defineProperty(this.prototype, name, descr));
    }
    return _results;
  };

  Urequire.property({
    BundleBuilder: {
      get: function() {
        return require("./process/BundleBuilder");
      }
    }
  });

  Urequire.property({
    NodeRequirer: {
      get: function() {
        return require('./NodeRequirer');
      }
    }
  });

  Urequire.property({
    Bundle: {
      get: function() {
        return require("./process/Bundle");
      }
    }
  });

  Urequire.property({
    Build: {
      get: function() {
        return require("./process/Build");
      }
    }
  });

  Urequire.property({
    UModule: {
      get: function() {
        return require("./process/UModule");
      }
    }
  });

  return Urequire;

})();

module.exports = new Urequire;
