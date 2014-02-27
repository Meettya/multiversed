###

  v0.0.4

###



foo       =            -> 'foo'

fooAsync  = (cb)       -> cb null, @foo()

fooAsyncHere = (cb)    -> cb null, foo()

summ      = (a, b)     -> a + b

summAsync = (a, b, cb) -> cb null, a + b

env_hundred_multi = (times)    -> @getRuntimeEnvValue('multi') 100, times

version = '0.0.4'

get_version = ->
  "Unprefixed  - #{@version}"

module.exports = {
  foo
  fooAsync
  fooAsyncHere
  summ
  summAsync
  env_hundred_multi
  version
  get_version
  _element_count_ : 10
}