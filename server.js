var express = require('express');
var app = express();
var path = require('path');
var fs = require('fs');

app.use(function staticsPlaceholder(req, res, next) {
  return next();
});

app.get('/', function(req, res) {
 res.sendfile('tmp/html/index.html');
});

app.get('*',
  function(req, res, next) {
    fs.readFile(path.resolve(__dirname, 'tmp/html/404.html'), {encoding: 'utf-8'}, function (error, data) {
      if (error) {
        next(error);
      } else {
        req.errorData = data;
        next();
      }
    });
  },
  function (req, res) {
    if (req.errorData) {
      res.send(404, req.errorData);
    } else {
      res.send(500, "An error occurred. Please try again later.");
    }
  }
);

app.use(require('connect-livereload')({
  port: 35729
}));

module.exports = app;
