#!/usr/bin/env coffee

###
Full Multiversed usage example 
###

root = __dirname
path = require 'path'

Multiversed = require path.join root, '..' # in real code `require 'multiversed'`

ImplementationDirectory = path.join root, '..', 'test', 'fixtures' # here placed product / versions implementation

# just to supress unnided for example messages
console.warn = ->

###
  Multiversed have 2 different way to init API factory:
    with ordinary callback or using EventEmmiter API.
  Because you cant init one factory twice - 
    I place two examle, you shoul chose one.
###

# 1) with callback

multiversed_cb = new Multiversed logger : console

multiversed_cb.initFactory ImplementationDirectory, (err, factory) ->
  return console.log "cb-style: #{err}" if err?
  console.log 'cb-style: factory inited!'

# 2) using EventEmmiter API

multiversed_ee = new Multiversed logger : console

multiversed_ee.on 'error', (err) -> console.log "EventEmmiter style: #{err}"
multiversed_ee.on 'ready', (factory) -> 
  console.log 'EventEmmiter style: factory inited!'
  multiversed_ready factory

multiversed_ee.initFactory ImplementationDirectory

###
BTW now we are able to request API realization 
###
multiversed_ready = (factory) ->

  product  = 'product_b'

  console.log "\n Results: \n"

  idx = 0 # for some strange reason we are cant use index AND range in one time
  for version_suffix in [3..8]

    version = "v0.0.#{version_suffix}"

    interface_api = factory.buildInterface product, version
    result = interface_api.executeSync true, 'get_version', 'Just prefix'

    console.log " #{++idx}) result for product |#{product}| with version |#{version}| - |#{result}|"

