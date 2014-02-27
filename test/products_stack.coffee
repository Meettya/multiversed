###
Test suite for node
###

lib_path = GLOBAL?.lib_path || ''

ProductsStack     = require "#{lib_path}products_stack"

describe 'ProductsStack:', ->

  test_obj = null

  fixtureRoot  = __dirname + "/fixtures"

  beforeEach ->
    console.warn = ->
    test_obj  = new ProductsStack logger : console

  describe '#new()', ->
    it 'should return object', ->
      test_obj.should.to.be.an.instanceof ProductsStack

  describe '#initStack()', ->

    it 'should init object and return self', (done) ->
      
      done_fn = (err, data) ->
        expect(err).to.be.null

        data.should.to.be.an.instanceof ProductsStack

        done()
      
      test_obj.initStack fixtureRoot, done_fn

    it 'should return error on init if already inited ', (done) ->

      done2_fn = (err, data) ->
        expect(err).not.to.be.null
        err.should.to.be.an.instanceof Error
        done()

      done_fn = (err, data) ->
        expect(err).to.be.null
        data.should.to.be.an.instanceof ProductsStack
      
        test_obj.initStack fixtureRoot, done2_fn

      test_obj.initStack fixtureRoot, done_fn

  describe '#getProduct()', ->


    it 'should return known product', (done) ->
      
      test_obj.initStack fixtureRoot, (err, self) ->

        product = 'product_a'
        
        result = self.getProduct product
        expect(result).not.to.be.null
        expect(result).not.to.be.undefined
        result.should.to.be.an 'object'

        result.should.to.respondTo 'buildVersion'

        done()

    it 'should return error for unknown product', (done) ->
    
      test_obj.initStack fixtureRoot, (err, self) ->

        product = 'product_undefined'

        expect(-> self.getProduct product).to.throw Error

        done()