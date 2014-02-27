###
Test suite for node
###

lib_path = GLOBAL?.lib_path || ''

BaseExecutor     = require "#{lib_path}base_executor"

describe 'BaseExecutor:', ->

  test_obj = null

  env_dict = 
    one : 1
    two : 2
    three : 3
    getFoo : -> 'foo'
    rand : (min, max) -> Math.round Math.random() * (max - min) + min

  fixture = 
    executes : 
      foo         :            -> 'foo'
      bar         : (cb)       -> cb null, 'bar'
      summ        : (a, b)     -> a + b
      mult_async  : (a, b, cb) -> cb null, a * b
      env_summ    : (a, b)     -> a + b + @getRuntimeEnv('one')['one']
      env_summ_2  : (a, b)     -> a + b + @getRuntimeEnvValue 'two'
      set_env     : (inn)      -> @setRuntimeEnv 'inner' : inn
      env_rand    : (max)      -> @getRuntimeEnvValue('rand') 0, max
      is_can_test : (method)   -> @isCommandExists method

    resolved_at :
      foo         : '0.0.3'
      bar         : '0.0.2'
      summ        : '0.0.1'
      mult_async  : '1.0.0'

  error_fixture = 
    executes : 
      foo     : -> 'foo'
      getRuntimeEnv  : -> 'getRuntimeEnv'
    resolved_at :
      foo     : '0.0.3'
      getRuntimeEnv  : '0.0.2'

  # просто сокращаем
  exec = fixture.executes

  beforeEach ->

    console.warn = ->
    test_obj  = new BaseExecutor fixture, logger : console

  describe '#new()', ->
    it 'should return object', ->
      test_obj.should.to.be.an.instanceof BaseExecutor

    it 'should throw error if reserved identifier used', ->
      expect( -> new BaseExecutor error_fixture ).to.throw Error

  describe '#isCommandExists()', ->

    it 'should return true for known command', ->
      
      command = 'foo'
      test_obj.isCommandExists(command).should.to.be.true

    it 'should return false for unknown command', ->
      
      command = 'kdjshkjsdhdfkjhdfs'
      test_obj.isCommandExists(command).should.to.be.false

    it 'should be available IN runtime env', ->
      test_obj.executeSync('is_can_test', 'foo').should.to.be.true
      test_obj.executeSync('is_can_test', 'jfhdkjdfhjkd').should.to.be.false

  describe '#executeSync()', ->

    it 'should execute known command without args', ->
      
      command = 'foo'
      res = test_obj.executeSync command
      res.should.to.be.eql exec[command]()

    it 'should execute known command with args', ->
      
      command = 'summ'

      res = test_obj.executeSync command, 2, 3
      res.should.to.be.eql exec[command]( 2, 3)

    it 'should return `undefined` on unknown command at lenient mode (by setup)', ->
      
      command = 'jfhdkjdfhjkd'
      expect(test_obj.executeSync true, command, 2, 3).to.be.undefined

    it 'should throw error on unknown command in strict mode (by default)', ->
      
      command = 'jfhdkjdfhjkd'
      expect(->test_obj.executeSync command, 2, 3).to.throw Error

    it 'should throw error on unknown command in strict mode (by setup)', ->
      
      command = 'jfhdkjdfhjkd'
      expect(->test_obj.executeSync false, command, 2, 3).to.throw Error

  describe '#execute()', ->

    it 'should execute known command without args', (done) ->
      
      command = 'bar'

      done_fn = (err, res) ->
        expect(err).to.be.null
        
        exec[command] (err2, sample) ->
          res.should.to.be.eql sample
          done()

      res = test_obj.execute command, done_fn


    it 'should execute known command with args', (done) ->
      
      command = 'mult_async'

      done_fn = (err, res) ->
        expect(err).to.be.null
        
        exec[command] 2, 3, (err2, sample) ->
          res.should.to.be.eql sample
          done()

      res = test_obj.execute command, 2, 3, done_fn

    it 'should return `undefined` on unknown command at lenient mode (by setup)', (done) ->
      
      command = 'jfhdkjdfhjkd'

      done_fn = (err, res) ->
        expect(err).to.be.null

        expect(res).to.be.undefined
        done()

      res = test_obj.execute true, command, 2, 3, done_fn


    it 'should return error on unknown command in strict mode (by default)', (done) ->
      
      command = 'jfhdkjdfhjkd'

      done_fn = (err, res) ->
        expect(err).not.to.be.null
        err.should.to.be.an.instanceof ReferenceError

        done()

      res = test_obj.execute command, 2, 3, done_fn

    it 'should return error on unknown command in strict mode (by setup)', (done) ->
      
      command = 'jfhdkjdfhjkd'

      done_fn = (err, res) ->
        expect(err).not.to.be.null
        err.should.to.be.an.instanceof ReferenceError

        done()

      res = test_obj.execute false, command, 2, 3, done_fn

  describe '#setRuntimeEnv()', ->

    it 'should set runtime environment and return self', ->
      res = test_obj.setRuntimeEnv env_dict
      res.should.to.be.an.instanceof BaseExecutor

    it 'should throw error if not plain object used', ->
      expect( -> test_obj.setRuntimeEnv [2,3,4] ).to.throw Error

    it 'should be available IN runtime env', ->
      test_obj.executeSync 'set_env', 2
      test_obj.getRuntimeEnv('inner').should.to.eql inner : 2

  describe '#getRuntimeEnv()', ->

    it 'should read runtime environment (arg - string)', ->
      test_obj.setRuntimeEnv env_dict
      test_obj.getRuntimeEnv('one').should.to.eql one : 1

    it 'should read runtime environment (arg - list)', ->
      test_obj.setRuntimeEnv env_dict 
      test_obj.getRuntimeEnv('one', 'two').should.to.eql one : 1, two : 2

    it 'should read runtime environment (arg - array)', ->
      test_obj.setRuntimeEnv env_dict
      test_obj.getRuntimeEnv(['one', 'two']).should.to.eql one : 1, two : 2

    it 'should return object with undefined value if key absent', ->
      test_obj.setRuntimeEnv env_dict
      test_obj.getRuntimeEnv('non-exist-key', 'one').should.to.eql 'non-exist-key' : undefined, one : 1

    it 'should be available IN runtime env', ->
      test_obj.setRuntimeEnv env_dict
      test_obj.executeSync('env_summ', 2, 3).should.to.be.eql 6

  describe '#getRuntimeEnvValue()', ->

    it 'should read runtime environment (arg - string)', ->
      test_obj.setRuntimeEnv env_dict
      test_obj.getRuntimeEnvValue('one').should.to.eql 1

    it 'should return undefined if key absent', ->
      test_obj.setRuntimeEnv env_dict
      expect(test_obj.getRuntimeEnvValue('non-exist-key')).to.be.undefined

    it 'should be available IN runtime env', ->
      test_obj.setRuntimeEnv env_dict
      test_obj.executeSync('env_summ_2', 2, 3).should.to.be.eql 7

    it 'should not cache data in runtime env', ->
      test_obj.setRuntimeEnv env_dict
      # get some more digits to ensure it will be different
      res1 = test_obj.executeSync 'env_rand', 10000
      res2 = test_obj.executeSync 'env_rand', 10000
      res1.should.not.to.be.eql res2

  describe '#whereResolved()', ->

    it 'should return for command version, where it resolved', ->
      res = test_obj.whereResolved 'foo'
      res.should.to.eql fixture.resolved_at.foo

    it 'should throw error for unknown command', ->
      expect( -> test_obj.whereResolved 'unknown_command' ).to.throw Error

  describe '#getFullResolvedList()', ->

    it 'should return all comand with versions, where its resolved', ->
      res = test_obj.getFullResolvedList()
      res.should.to.eql fixture.resolved_at




