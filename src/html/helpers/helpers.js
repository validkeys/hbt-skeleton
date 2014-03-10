'use strict';

module.exports = function (handlebars, _) {

  handlebars.registerHelper("debug", function(){
    msg = ""
    for (var property in this) {
      msg += property + ': ' + this[property]+'; ';
    }
    return new handlebars.SafeString(msg)
  });

};
