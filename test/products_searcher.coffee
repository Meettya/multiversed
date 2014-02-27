###
Test suite for node
###

lib_path = GLOBAL?.lib_path || ''

ProductsSearcher     = require "#{lib_path}products_searcher"

describe 'ProductsSearcher:', ->

  # это нужно для очистки лога тестов, потому что серчер будет ругаться на невалидные данные
  _console_warn = console.warn

  test_obj = null

  fixtureRoot  = __dirname + "/fixtures"

  beforeEach ->
    test_obj  = new ProductsSearcher

  describe '#new()', ->
    it 'should return object', ->
      test_obj.should.to.be.an.instanceof ProductsSearcher

  describe '#proceedDirectory()', ->

    # тут у нас часть тестов будет ругаться на невалидные файлы - скрываем для чистоты
    before ->
      console.warn = ->
    after ->
      console.warn = _console_warn

    it 'should proceed directory and find some sub-dirs', (done) ->

      done_fn = (err, data) ->
        expect(err).to.be.null

        data.should.not.to.be.a.null
        data.should.not.to.be.a.undefined
        data.should.to.be.an 'array'

        done()
      
      test_obj.proceedDirectory fixtureRoot, done_fn

