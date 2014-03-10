"use strict"

path = require('path')
_ = require('lodash')

module.exports = (grunt) ->

  require('time-grunt')(grunt)

  require('load-grunt-tasks')(grunt)

  workingDirectory = if grunt.option('target')? then grunt.option('target') else '.'

  pkg = grunt.file.readJSON("package.json")

  # configurable paths
  config =
    src: 'src'
    tmp: "#{workingDirectory}/tmp"
    port: 9393

  vendorjs = [
    "./bower_components/jquery/dist/jquery.js"
    "./bower_components/underscore/underscore.js"
    "./bower_components/fastclick/lib/fastclick.js"
  ]

  hbtFiles = [
    "<%= pkg.tmppath %>html/404.html": "<%= pkg.srcpath %>html/errors/404.hbt"
  ]

  appConfig = require('./config/settings.json')
  hbtData = require('./src/html/data/data.json')
  devData = _.extend(_.clone(hbtData), appConfig.development)
  prodData = _.extend(_.clone(hbtData), appConfig.production)

  # Project configuration.
  grunt.initConfig

    config: config
    vendorjs: vendorjs

    pkg: pkg
    meta: {}

    watch:

      scripts:
          files: ["<%= pkg.srcpath %>javascripts/**/*.coffee", "!<%= pkg.srcpath %>javascripts/vendor/**/*.coffee"]
          tasks: ["coffee:dev", "coffee:devMain", "concat:appjsdev"]

      css:
          files: ["<%= pkg.srcpath %>stylesheets/**/*.scss"]
          tasks: ["compass", "concat:cssdev", "clean:tmpcss"]

      html:
          files: ["./config/settings.json","<%= pkg.srcpath %>html/**/*.hbt","<%= pkg.srcpath %>html/data/data.json","<%= pkg.srcpath %>html/helpers/helpers.js"]
          tasks: ["hbt:dev"]

      images:
          files: "<%= pkg.srcpath %>assets/images"
          tasks: ["copy:dev"]

    coffee:
      dev:
        files: [
          src: [
            "./src/javascripts/**/*.coffee"
            "!./src/javascripts/main.coffee"
            "!./src/javascripts/vendor/**/*.coffee"
          ]
          dest: "./tmp/js/libs.js"
        ]
      devMain:
        files: [
          src: [
            "./src/javascripts/main.coffee"
          ]
          dest: "./tmp/js/main.js"
        ]


    hbt:
      options:
        data: devData
        partials: '<%= pkg.srcpath %>html/**/_*.hbt'
        helpers:  '<%= pkg.srcpath %>html/helpers/*.js'
        processPartialName: (filePath) ->
          pieces = filePath.split("/");
          # grunt.log.write pieces
          pieces[pieces.length - 1].replace(".hbt","").substring(1)
      dev:
        options:
          data: devData
        files: hbtFiles
      prod:
        options:
          data: prodData
        files: hbtFiles

    compass:
      dev:
        options:
          sassDir: "<%= pkg.srcpath %>stylesheets/"
          cssDir: "<%= pkg.tmppath %>css/all/"
      bootstrap:
        options:
          sassDir: "./bower_components/twbs-bootstrap-sass/vendor/assets/stylesheets/bootstrap/"
          cssDir: "<%= pkg.tmppath %>css/all/"

    concat:
      cssdev:
        src: [
          "./bower_components/animate.css/animate.css"
          "<%= pkg.tmppath %>css/all/**/*.css"
        ]
        dest: "<%= pkg.tmppath %>css/application.css"
      vendorjsdev:
        src: vendorjs
        dest: "<%= pkg.tmppath %>js/vendor.js"
      appjsdev:
        src: ["<%= pkg.tmppath %>js/libs.js", "<%= pkg.tmppath %>js/main.js"]
        dest: "<%= pkg.tmppath %>js/app.js"
      prodcss:
        src:  "<%= pkg.distpath %>css/all/application.css"
        dest: "<%= pkg.distpath %>css/styles.css"
      prodjs:
        src: vendorjs
        dest: "<%= pkg.distpath %>js/all.js"

    clean:
      tmp: ["<%= pkg.tmppath %>"]
      tmpcss: ["<%= pkg.tmppath %>css/all/"]
      prodcss: [
        "<%= pkg.distpath %>css/application.css"
      ]
      dist: ["<%= pkg.distpath %>"]
      prodjs: ["<%= pkg.distpath %>js/all/"]

    copy:
      dev:
        files: [
          expand: true
          cwd: "<%= pkg.srcpath %>css/"
          src: ["*.css"]
          dest: "<%= pkg.tmppath %>css/"
        ,
          expand: true
          cwd: "<%= pkg.srcpath %>assets/"
          src: ["**"]
          dest: "<%= pkg.tmppath %>assets/"
        ]
      prod:
        files: [
          expand: true
          cwd: './tmp/css/'
          src: ["*.css"]
          dest: "./dist/css/"
        ,
          expand: true
          cwd: "./tmp/assets/"
          src: ["**"]
          dest: "./dist/assets/"
        ,
          expand: true
          cwd: "./tmp/js/"
          src: ["**"]
          dest: "./dist/js/all/"
        ]

    uglify:
      prod:
        files:
          "./dist/js/app.min.js": [
            "./dist/js/all/vendor.js",
            "./dist/js/all/app.js"
          ]


    processhtml:
      dist:
        files:[
          expand: true
          cwd: "./tmp/html/"
          src: ["*.html"]
          dest: "./dist/"
        ]


    express:
      livereload:
        options:
          port: config.port
          server: path.resolve('server')
          bases: ['tmp']
          livereload: true

    cssmin:
      minify:
        expand: true
        cwd: './dist/css/'
        src: 'application.css'
        dest: './dist/css/'
        ext: '.min.css'


    useminPrepare:
      html: './tmp/html/*.html'
      options:
        dest: './dist/'

    usemin:
      html: ['./dist/{,*/}*.html']
      options:
        dirs: ['./dist/']

    # compress:
    #   main:
    #     options:
    #       mode: "gzip"
    #     files: [
    #       expand: true
    #       cwd: './dist/js/'
    #       src: 'app.min.js'
    #       dest:'./dist/js/'
    #     ,
    #       expand: true
    #       cwd: './dist/css/'
    #       src: 'styles.min.css'
    #       dest:'./dist/css/'
    #     ,
    #       expand: true
    #       cwd: './dist/fonts/'
    #       src: ['*']
    #       dest:'./dist/fonts/'
    #     ]

    open:
      dev:
        path: 'http://localhost:<%= config.port %>'
        app: 'Google Chrome'

  server_tasks = [
    "clean:tmp",
    "compass",
    "concat:cssdev",
    "concat:vendorjsdev",
    "coffee:dev",
    "coffee:devMain",
    "concat:appjsdev",
    "clean:tmpcss",
    "copy:dev",
    "hbt:dev",
    "express:livereload",
    "watch",
    "express-keepalive"
  ]

  grunt.registerTask "build", "Runs a full or partial build", ->

    dev_tasks   = [
      "clean:dist",
      "clean:tmp",
      "compass",
      "concat:cssdev",
      "concat:vendorjsdev",
      "coffee:dev",
      "clean:tmpcss",
      "copy:dev",
    ]
    prod_tasks  = [
      "hbt:prod"
      "processhtml"
      "copy:prod",
      "cssmin:minify",
      "clean:prodcss",
      "uglify:prod",
      "clean:prodjs"
    ]

    grunt.task.run(dev_tasks)
    grunt.task.run(prod_tasks)


  # grunt.registerTask "deploy", "Runs build then deploys files to s3", ->
  #   grunt.task.run('build')
  #   grunt.task.run("compress")
  #   grunt.task.run('s3')

  grunt.registerTask "server", server_tasks
  grunt.registerTask "default", ["server"]
  grunt.registerTask "openDev", "open:dev"
