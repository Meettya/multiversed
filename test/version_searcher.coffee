###
Test suite for node
###

lib_path = GLOBAL?.lib_path || ''

VersionsSearcher     = require "#{lib_path}versions_searcher"

describe 'VersionsSearcher:', ->

  # это нужно для очистки лога тестов, потому что серчер будет ругаться на невалидные данные
  _console_warn = console.warn

  test_obj = null

  fixtureRoot  = __dirname + "/fixtures"
  valid_fixture = fixtureRoot + '/product_a'
  valid_fixture2 = fixtureRoot + '/product_b'

  beforeEach ->
    test_obj  = new VersionsSearcher

  describe '#new()', ->
    it 'should return object', ->
      test_obj.should.to.be.an.instanceof VersionsSearcher

  describe '#proceedDirectory()', ->

    # тут у нас часть тестов будет ругаться на невалидные файлы - скрываем для чистоты
    before ->
      # console.warn = ->
    after ->
      console.warn = _console_warn

    it 'should proceed directory and find some files (v0.0.0-1 style)', (done) ->

      done_fn = (err, data) ->
        expect(err).to.be.null

        data.should.not.to.be.a.null
        data.should.not.to.be.a.undefined
        data.should.to.be.an 'object'

        data.should.not.to.be.empty

        done()
      
      test_obj.proceedDirectory valid_fixture, done_fn

    it 'should proceed directory and find some files (v0.0.1 style)', (done) ->

      done_fn = (err, data) ->
        expect(err).to.be.null

        data.should.not.to.be.a.null
        data.should.not.to.be.a.undefined
        data.should.to.be.an 'object'

        data.should.not.to.be.empty

        done()
      
      test_obj.proceedDirectory valid_fixture2, done_fn

    it 'should return error on non-semver files in `strict` mode', (done) ->

      test_obj  = new VersionsSearcher strict : on

      done_fn = (err, data) ->
        expect(err).not.to.be.null
        err.should.to.be.an.instanceof Error

        done()
      
      test_obj.proceedDirectory valid_fixture, done_fn