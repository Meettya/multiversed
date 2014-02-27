###
Test suite for node
###

lib_path = GLOBAL?.lib_path || ''

ComponentFactory     = require "#{lib_path}component_factory"

# для теста
BaseExecutor    = require "#{lib_path}base_executor"

_     = require 'lodash'

describe 'ComponentFactory:', ->

  test_obj = null

  fixtureRoot     = __dirname + "/fixtures"
  fixtureNonExist = __dirname + "/notexisted_dir"

  beforeEach ->
    console.warn = ->
    test_obj  = new ComponentFactory logger : console

  describe '#new()', ->
    it 'should return object', ->
      test_obj.should.to.be.an.instanceof ComponentFactory

  describe '#initFactory()', ->

    it 'should init object and return self', (done) ->
      
      done_fn = (err, data) ->
        expect(err).to.be.null

        data.should.to.be.an.instanceof ComponentFactory

        done()
      
      test_obj.initFactory fixtureRoot, done_fn

    it 'should throw error on init if already inited', (done) ->

      done2_fn = (err, data) ->
        expect(err).not.to.be.null
        err.should.to.be.an.instanceof Error
        done()

      done_fn = (err, data) ->
        expect(err).to.be.null
        data.should.to.be.an.instanceof ComponentFactory
      
        test_obj.initFactory fixtureRoot, done2_fn

      test_obj.initFactory fixtureRoot, done_fn

    it 'should throw error if dir not string', (done) ->
      done_fn = (err, data) ->
        expect(err).not.to.be.null
        err.should.to.be.an.instanceof Error
        done()
      
      test_obj.initFactory null, done_fn

    it 'should throw error if dir not exist', (done) ->
      done_fn = (err, data) ->
        expect(err).not.to.be.null
        err.should.to.be.an.instanceof Error
        done()
      
      test_obj.initFactory fixtureNonExist, done_fn

    it 'should ignore (but warn) if nobody care about init (no cb or listener)', (done) ->

      test_obj.initFactory fixtureRoot
      done()

    it 'should init object and emit event "ready" (using EventEmitter interface)', (done) ->
      
      done_fn = (data) ->
        data.should.to.be.an.instanceof ComponentFactory
        done()

      test_obj.on 'ready', done_fn
      test_obj.initFactory fixtureRoot

    it 'should init object *and use both interface* (cb & event)', (done) ->
      
      # yes, after both
      done_all = _.after 2, done

      event_done_fn = (data) ->
        data.should.to.be.an.instanceof ComponentFactory
        done_all()

      cb_done_fn = (err, data) ->
        expect(err).to.be.null
        data.should.to.be.an.instanceof ComponentFactory
        done_all()

      test_obj.on 'ready', event_done_fn
      test_obj.initFactory fixtureRoot, cb_done_fn

    it 'should emit event "error" on init if already inited (using EventEmitter interface)', (done) ->
      
      error_fn = (err) ->
        expect(err).not.to.be.null
        err.should.to.be.an.instanceof Error
        done()

      test_obj.on 'error', error_fn
      test_obj.initFactory fixtureRoot
      test_obj.initFactory fixtureRoot

  describe '#buildInterface()', ->

    it 'should return known product (as Executor)', (done) ->
      
      test_obj.initFactory fixtureRoot, (err, self) ->

        product = 'product_a'
        version = '1.0.0'

        result = self.buildInterface product, version
        expect(result).not.to.be.null
        expect(result).not.to.be.undefined
        result.should.to.be.an 'object'
        result.should.to.be.instanceof BaseExecutor

        result.should.to.respondTo 'isCommandExists'

        done()

    it 'should return error for unknown product', (done) ->
    
      test_obj.initFactory fixtureRoot, (err, self) ->

        product = 'product_undefined'
        version = '0.0.1'

        expect(-> self.buildInterface product, version ).to.throw Error

        done()


    it 'should return error for unspecified product', (done) ->
    
      test_obj.initFactory fixtureRoot, (err, self) ->

        expect(-> self.buildInterface()).to.throw Error

        done()

    it 'should return error for unspecified version', (done) ->
    
      test_obj.initFactory fixtureRoot, (err, self) ->

        product = 'product_undefined'

        expect(-> self.buildInterface product).to.throw Error

        done()

    it 'should return error on uninitialized object', ->
    
      expect(-> test_obj.buildInterface product, version ).to.throw Error

  describe 'resolved interface itself', ->

    it 'should have overwritten value by greater version (in case `this` used)', (done) ->

      test_obj.initFactory fixtureRoot, (err, self) ->

        product = 'product_b'
        version = '1.0.0'

        implement = self.buildInterface product, version

        result = implement.executeSync 'foo'

        expect(result).not.to.be.null
        expect(result).not.to.be.undefined
        
        result.should.to.be.eql 'foo`'

        done()

    it 'should use overwritten value into not-owerwriten function (in case `this` used)', (done) ->

      test_obj.initFactory fixtureRoot, (err, self) ->

        product = 'product_b'
        version = '1.0.0'

        implement = self.buildInterface product, version

        implement.execute 'fooAsync', (err, result) ->
          expect(err).to.be.null

          expect(result).not.to.be.null
          expect(result).not.to.be.undefined
        
          result.should.to.be.eql 'foo`'

          done()

    it 'should use domestic value instead of overwritten (in case local assignment used)', (done) ->

      test_obj.initFactory fixtureRoot, (err, self) ->

        product = 'product_b'
        version = '1.0.0'

        implement = self.buildInterface product, version

        implement.execute 'fooAsyncHere', (err, result) ->
          expect(err).to.be.null

          expect(result).not.to.be.null
          expect(result).not.to.be.undefined
        
          result.should.to.be.eql 'foo'

          done()

    it 'should correct resolve #getRuntimeEnvValue()', (done) ->

      test_obj.initFactory fixtureRoot, (err, self) ->

        product = 'product_b'
        version = '1.0.0'

        implement = self.buildInterface product, version

        implement.setRuntimeEnv multi : (a, b) -> a * b

        result = implement.executeSync 'env_hundred_multi', 5

        expect(result).not.to.be.null
        expect(result).not.to.be.undefined
        
        result.should.to.be.eql 500

        done()