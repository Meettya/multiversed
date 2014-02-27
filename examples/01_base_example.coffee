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

# our target API
product  = 'product_b'
version  = '0.0.5'

# create factory
multiversed_cb = new Multiversed logger : console

# init it with callback style (also we are have EventEmmiter - see 02_full_example)
multiversed_cb.initFactory ImplementationDirectory, (err, factory) ->
  return console.log "cb-style: #{err}" if err?
  console.log 'cb-style: factory inited!'
  # resolve interface for product and version
  interface_api = factory.buildInterface product, version
  # execute some command for interface
  result = interface_api.executeSync 'get_version', 'Just prefix'
  console.log "\n Results: \n"
  console.log " result for product |#{product}| with version |#{version}| - |#{result}|"
