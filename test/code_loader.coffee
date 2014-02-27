###
Test suite for node
###

path  = require 'path'

lib_path = GLOBAL?.lib_path || ''

CodeLoader     = require "#{lib_path}code_loader"

describe 'CodeLoader:', ->

  test_obj = null

  fixtureRoot  = __dirname + '/fixtures'
  valid_fixture = fixtureRoot + '/examples'

  # just HARDCODE this to simplify test itself
  # if something changed at fixtures - change it
  filenames = 
    '.coffee' : 'cs_file.coffee'
    '.js'      : 'js_file.js'
    '.json'    : 'json_file.json'
  

  beforeEach ->
    test_obj  = new CodeLoader

  describe '#new()', ->
    it 'should return object', ->
      test_obj.should.to.be.an.instanceof CodeLoader

  describe '#processSources()', ->

    it 'should load `js` files content', ->
      
      filename = path.join valid_fixture, filenames['.js']

      data = test_obj.loadCode filename
      expect(data).to.be.an 'object'
      data.rem(5,3).should.to.be.eql 2

    it 'should load `coffee` files content (with sub-require)', ->
      
      filename = path.join valid_fixture, filenames['.coffee']

      data = test_obj.loadCode filename
      expect(data).to.be.an 'object'
      data.first([2,3,4]).should.to.be.eql 2

    it 'should load `json` files content', ->
      
      filename = path.join valid_fixture, filenames['.json']

      data = test_obj.loadCode filename
      expect(data).to.be.an 'object'
      data.yes.should.to.be.true

