###
Test suite for node
###
_ = require 'lodash'

lib_path = GLOBAL?.lib_path || ''

VersionsStack     = require "#{lib_path}versions_stack"

describe 'VersionsStack:', ->

  # это нужно для очистки лога тестов, потому что серчер будет ругаться на невалидные данные
  _console_warn = console.warn
  # тут у нас часть тестов будет ругаться на невалидные файлы - скрываем для чистоты
  before ->
    console.warn = ->
  after ->
    console.warn = _console_warn

  test_obj = null

  fixtureRoot     = __dirname + "/fixtures"
  valid_fixture   = fixtureRoot + '/product_a'
  valid_fixture2  = fixtureRoot + '/product_b'

  beforeEach ->
    test_obj  = new VersionsStack

  describe '#new()', ->
    it 'should return object', ->
      test_obj.should.to.be.an.instanceof VersionsStack

  describe '#initStack()', ->

    it 'should init object and return self', (done) ->
      
      done_fn = (err, data) ->
        expect(err).to.be.null

        data.should.to.be.an.instanceof VersionsStack

        done()
      
      test_obj.initStack valid_fixture, done_fn

    it 'should return error on init if already inited ', (done) ->

      done2_fn = (err, data) ->
        expect(err).not.to.be.null
        err.should.to.be.an.instanceof Error
        done()

      done_fn = (err, data) ->
        expect(err).to.be.null
        data.should.to.be.an.instanceof VersionsStack
      
        test_obj.initStack fixtureRoot, done2_fn

      test_obj.initStack fixtureRoot, done_fn


  describe '#buildVersion()', ->

    it 'should build matched version to defined', (done) ->
      
      test_obj.initStack valid_fixture, (err, self) ->

        version = 'v0.0.0-02'
        
        result = self.buildVersion version
        expect(result).not.to.be.null
        expect(result).not.to.be.undefined
        result.should.to.be.an 'object'

        result.executes.version.should.to.be.eql '0.0.0-2'

        done()

    it 'should build overnumberd version to defined', (done) ->
      
      test_obj.initStack valid_fixture, (err, self) ->

        version = 'v1.0.0'
        
        result = self.buildVersion version
        expect(result).not.to.be.null
        expect(result).not.to.be.undefined
        result.should.to.be.an 'object'

        result.executes.version.should.to.be.eql '0.0.1-2'

        done()

    it 'should build lowers version to `empty` object', (done) ->
      
      test_obj.initStack valid_fixture, (err, self) ->

        version = 'v0.0.0-00'
        
        result = self.buildVersion version
        expect(result).not.to.be.null
        expect(result).not.to.be.undefined
        result.should.to.be.an 'object'

        expect(_.keys result.executes).to.have.length 0

        done()

    it 'should build intermediate version by closest non-greater version', (done) ->
      
      test_obj.initStack valid_fixture, (err, self) ->

        version = 'v0.0.0-05'
        
        result = self.buildVersion version
        expect(result).not.to.be.null
        expect(result).not.to.be.undefined
        result.should.to.be.an 'object'

        result.executes.version.should.to.be.eql '0.0.0-2'

        done()

    it 'should build closest non-greater version for pre-release (0.0.4 < 0.0.5-rc1 < 0.0.5)', (done) ->
      
      test_obj.initStack valid_fixture2, (err, self) ->

        version = 'v0.0.5-rc1'
        
        result = self.buildVersion version
        expect(result).not.to.be.null
        expect(result).not.to.be.undefined
        result.should.to.be.an 'object'

        result.executes.version.should.to.be.eql '0.0.4'

        done()