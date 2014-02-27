#!/usr/bin/env coffee

###
Full Multiversed usage example 
###

root = __dirname
path = require 'path'
util = require 'util'


Multiversed = require path.join root, '..' # in real code `require 'multiversed'`

ImplementationDirectory = path.join root, '..', 'test', 'fixtures' # here placed product / versions implementation

# just to supress unnided for example messages
console.warn = ->

multiversed = new Multiversed logger : console

multiversed.on 'error', (err) -> console.log "EventEmmiter style: #{err}"
multiversed.on 'ready', (factory) -> 
  console.log 'EventEmmiter style: factory inited!'
  multiversed_ready factory

multiversed.initFactory ImplementationDirectory

###
work with API realization 
###
multiversed_ready = (factory) ->

  product  = 'product_b'

  calculations = 
    'value access example' : ->
      factory.buildInterface(product, 'v0.0.5').executeSync 'get_elements_count'
    'function access example' : ->
      factory.buildInterface(product, 'v0.0.6').executeSync 'multiple_elements_count_by', 3
    'available test example' : ->
      util.inspect factory.buildInterface(product, 'v0.0.8').executeSync 'available_test'

  console.log "\n Results: \n"

  idx = 0
  for name, value_fn of calculations
    console.log " #{++idx}) executing #{name} with result |#{value_fn()}|"

