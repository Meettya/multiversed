[![Build Status](https://secure.travis-ci.org/Meettya/multiversed.png)](http://travis-ci.org/Meettya/multiversed)  [![Dependency Status](https://gemnasium.com/Meettya/multiversed.png)](https://gemnasium.com/Meettya/multiversed)

# Multiversed

**Multiversed** - tool for creating versioned API within a single code base.

Can treat it as a kind of analogue GitHub in runtime - specifying the target product and version changes as transparently self API, and its implementation.

The reason for creating - need to be able to implement an arbitrary subset API, maintaining a single code base to construct a functional automation desired configuration inheritance functional and its redefinition.

## How to work with it

### The minimum example

Minimal example to demonstrate how to work with:

```
Multiversed = require 'multiversed'
ImplementationDirectory = 'implementation_dir' # full path to the API implementations

# create a factory
multiversed_cb = new Multiversed

# initiate it using the callback (as there is EventEmmiter interface)
multiversed_cb.initFactory ImplementationDirectory, (err, factory) ->

  # Our target API was build for this product with a specific version
  product  = 'product_b'
  version  = '0.0.5'

  # resolve the interface to the desired version
  interface_api = factory.buildInterface product, version

  # and now we can perform some action with the resulting interface
  result = interface_api.executeSync 'get_version', 'Just prefix'

  console.log result # -> Just prefix - 0.0.5

```
See `examples/01_base_example` for additional info.

### Sample detail

Profit was not something obvious, but let's extend the example, rewriting callback initiation :
```
# Initiate it using the callback (as there is EventEmmiter interface)
multiversed_cb.initFactory ImplementationDirectory, (err, factory) ->

  product  = 'product_b'

  test_steps = [
    '0.0.3'
    '0.0.4'
    '0.0.5'
    '0.0.6'
    '0.0.7'
    '0.0.8'
  ]

  for version, idx in test_steps

    interface_api = factory.buildInterface product, version
    # Use "lazy" style challenge - the absence of the discharge does not cause exceptions
    # In production code is better to use the pre- check interface_api.isCommandExists 'get_version'
    result = interface_api.executeSync true, 'get_version', 'Just prefix'

    console.log "#{idx+1}) result for product |#{product}| with version |#{version}| - |#{result}|"

```
Additionally, see `examples/02_full_example`.

Now the console will output a bit more interesting :
```
1) result for product |product_b| with version |0.0.3| - |undefined|
2) result for product |product_b| with version |0.0.4| - |Unprefixed  - 0.0.4|
3) result for product |product_b| with version |0.0.5| - |Just prefix - 0.0.5|
4) result for product |product_b| with version |0.0.6| - |Just prefix - 0.0.6|
5) result for product |product_b| with version |0.0.7| - |Just prefix - 0.0.6|
6) result for product |product_b| with version |0.0.8| - |Unprefixed  - 0.0.8|
```
implementations (see the complete source code `test / fixtures / product_b`):
```
#v0.0.3 - absent
# using a normal (non- lazy ) query command
# will throw an exception for unrealized API

#v0.0.4
# Defined for the first time
get_version = ->
  "Unprefixed  - #{@version}"

#v0.0.5
# ad-hock Override
get_version = (prefix) ->
  "#{prefix} - #{@version}"

#v0.0.6
# Inherited from default v0.0.5

#v0.0.7 - absent
# Inherited from v0.0.6 default including version value

#v0.0.8
# Override using from an older implementation
{ get_version } = require './v0.0.4'
```

## Where is the profit that?

**Multiversed** provides a number of non-obvious pluses:

### Advantages over clean "configuration"

  - Allows you to create implementation files only if there are changes versioned independently implementing intermediate and older versions
  - Allows you to make the switching logic implementation of the basic logic of the program - in the case of pure "configuration" is the probability of spreading state diagram
  - Allows you to "branch to the" implementation of the interfaces - very useful if you have several deploys be a release branches (put something we released version v.2.0.1 but must also maintain v1.84.1718, where eventually there will be some decisions that make no sense branch in v2)

### Advantages over inheritance

  - Implements flat sibling of versioned object structure of any size - with very large structure time will be spent only once to an assembly (which will be further optimized in addition to) the classical inheritance of deeply nested object will case problems
  - Implements a flat object sibling guaranteed O(1) providing an implementation method or notifying his absence - in the classic "deep" inheritance "method missing" can be quite expensive
  - Allows you to build the interface from anywhere, an unlimited number of sources, no problem "base class fragility"
  - Allows you to override the implementation, using the definition of any distance, in the inheritance of behavior back "grand-grand-grandfather", redefined in the ancestors - almost impossible

### Advantages over mixines

  - Mixines allow flexibility to implement objects, combining the required methods, however, do not provide a clear opportunity to override methods, demanding circuit description states

And a number of non-obvious drawbacks :

### The disadvantages of using Multiversed

  - Is required to strictly adhere to the rules - only in the implementation of their respective classes in versioned files - just call these methods (otherwise violated all principles of SOLID- especially if the tool is condoning this )
  - The implementation of non-obviousness (compared to classical schemes )
  - Complicated debugging (although the use of built-in tools should help )

## Still not sure what I need it

Most likely because it is - at this tool very specific use case. **Multiversed** was not written by a good life and is designed to solve the problem of "how to make a matrix product M*N, while maintaining a single code base".

**Multiversed** will help if you have incompatible releases in which minor updated version or if your service is an intermediary between a number of data providers and data users, you do not control, or if you have it all at once and all actively developing and changing - in general if you have a really big problem is uncontrolled, solutions for which you are willing to endure the problem of controlled medium size.

In short - **multiversed** damn bitter medicine with lots of side effects, but the alternative is worse - saw the surgeon.

## Ok, show me the code

The cycle with **multiversed** divided into 2 parts - the interaction with the factory interfaces and implementation API performer, build by factory.

Necessary explanations about the files themselves are also versions given hereinafter.

### Factory API

The factory itself implements a constructor and 2 method:

#### #new(options)
```
@param {Object}    options     constructor parameters
```
```
multiversed = new Multiversed 
```
The constructor accepts an object :

  - `logger` - object implementation logging, by default `console` (DI in pure form, the object passed in must implement the API `console`)
  - `strict` - flag strict regime, if it is installed - deviations that may be errors, typos (in catalogs, etc.) - must throw an error (not really yet implemented)

#### #initFactory(dir [, cb])
```
@param {String}    dir     target directory
@param {Function}  cb      (optional) callback
```

```
# using callback
multiversed.initFactory 'some_dir', (err, factory) ->
  onFactoryReady factory

# or using EventEmmiter
multiversed.on 'ready', (factory) -> 
  onFactoryReady factory
multiversed.initFactory 'some_dir'
```

Yes, you can use any style to initiate treatment plant, the directory path should be complete.

Factory can initiate only once (maybe this behavior will be changed in the future)

#### #buildInterface(product, version)
```
@param {String}   product   name of the product
@param {String}   version   target system version
```


```
onFactoryReady = (factory) ->
  interfaceObject = factory.buildInterface 'awesome_product', 'v2.0.3-beta'
```

Requires a product and version :

  - `product` - directory `some_dir` there should be a subdirectory `awesome_product`
  - `version` - any validly in terms `semver`, version for which you want to build API

If the discrepancy `product` throws an exception, it will give an indication of a non-existent version or implementation of the nearest smaller version (do not forget that from the standpoint of `semver` beta lower than usual `0.0.4 < 0.0.5-rc1 < 0.0.5`) or return an empty implementation - API is built, but he knows how to do it.

Build interfaces can be any number of times.

### Executor API

Factory returns an object that encapsulates within itself built API and some utility methods

#### #execute([is_lenient,] command [, args...], cb)
```
@params {Boolean}   is_lenient  (optional)  optional key - if false or no - will throw an error on unknown command if true - just undefined
@params {String}    command                 command
@params {Any}       args        (optional)  arguments
@params {Function}  cb                      calback
```
```
interfaceObject.execute 'some_command', (err, result) ->
```

Asynchronously executes the specified command, returning the result in the callback (no callbacks will be thrown), may take any number of arguments, and an optional flag "lazy mode".

You have to understand that the team itself should be implemented taking into account the asynchronous reference to it, otherwise you may get strange results.

#### #executeSync([is_lenient,] command [, args...])
```
@params {Boolean}   is_lenient  (optional)  optional key - if false or no - will throw an error on unknown command if true - just undefined
@params {String}    command                 command
@params {Any}       args        (optional)  arguments
```
```
result = interfaceObject.executeSync 'some_sync_command', arg_1, arg_2
```

Synchronously executes the specified command, returning the result, may take any number of arguments, and an optional flag "lazy mode".

You have to understand that the team itself must be synchronous, asynchronous synchronous execution of API commands most likely give you a strange result.

#### #isCommandExists(command)
```
@params {String} command  to check the name of the command
```
```
if interfaceObject.isCommandExists 'some_command'
  interfaceObject.execute 'some_command', (err, result) ->
```

Checks whether there is such a team is preferable to use this method for verifying the implemented interface .

Mainly used _outside_ object API, but can also be used inside.

#### #getRuntimeEnvValue(key)
```
@params {String} key on the key parameter that needs
@return {Mixed}
```
```
some_param_value = interfaceObject.getRuntimeEnvValue 'some_param'
```

Returns the value for one parameter of the environment of the runtime command.

Mainly used _inside_ object API, but can also be used outside.

#### #getRuntimeEnv(keys...)
```
@params {Mixed} keys  key / key list / array with a list of keys
@return {Object}
```
```
some_params = interfaceObject.getRuntimeEnv 'some_param', 'another_param'
###
some_params = 
  some_param    : 'value'
  another_param : 'value_2'
###
```

Returns an object with parameters from the runtime environment of the team.

Mainly used _inside_ object API, but can also be used outside.

#### #setRuntimeEnv(env_object)
```
@param {Object} env_object object with properties runtime 
```
```
interfaceObject.setRuntimeEnv new_param : 'value_3'
```

Sets (adds or overwrites) runtime environment execution.

Mainly used _outside_ object API, but can also be used inside.

#### #whereResolved(command)
```
@params {String} command  to check the name of the command
```
```
console.log interfaceObject.whereResolved 'some_command'
```
Tells what version command was resolved (defined).

Extremely useful for testing and debugging.

#### #getFullResolvedList()
```
console.log interfaceObject.getFullResolvedList()
```
Returns the full list of commands with a version in which they were resolved (defined).

Extremely useful for testing and debugging.

### File of version

#### The base functionality

Functionally file version works almost the same way as a standard module node.js - requests additional functionality through the `require` and exports functions using the object `module.exports`.

Specificity file versions lies in the fact that the execution context (aka `this`) is assigned to the resulting combined entity , i.e. you can do something like :
```
# v0.0.4
module.exports = 
  _element_count_ : 10

# v0.0.5
module.exports = 
  get_elements_count : -> @_element_count_
```
True, the data is also required to export, but access is possible only within modules versions, API artist does not offer this option (because it is a bad practice). If the data is still needed - create a wrapper function to obtain them.

Similarly, you can access other functions declared in parent module:
```
# v0.0.6
module.exports = 
  multiple_elements_count_by : (number) ->
    @get_elements_count() * number
```

#### Mixines

In addition to the final realization of the functions are mixed performer, to be able to have access to them _inside_ module itself, here's the list:
```
  getRuntimeEnv
  getRuntimeEnvValue
  setRuntimeEnv
  isCommandExists
```
These methods are reserved words, their use in the configuration files will cause an error.

Apply them can do something like:
```
# v0.0.8
available_test = ->
  'existing method'     : @isCommandExists 'multiple_elements_count_by'
  'non-existing method' : @isCommandExists 'sdkjgskdjgdskgdskj'

module.exports = 
  { available_test }
```
and when you call (API version v0.0.8) get
```
{ 'existing method': true, 'non-existing method': false }
```

##### RuntimeEnv

Group methods `*RuntimeEnv*` was introduced for transparent access to registry variables runtime of his name (registry) should be used for the transmission of API objects of type "database connection" (or pull), "configuration file", etc. shared resources.

## If you do not understand something

The module comes with a directory `example` for a detailed study of the examples directory and `test`, which actually describes the product specification.

## I found a bug or lacking functional

Feel free to open the issue, so you can help improve the code and documentation.

## I want to help with the translation of documentation

Just perfect! At now, as you see, I use Google translate.

Do, please, fork and merge request to transfer, do not forget to include yourself in the section **Acknowledgements** :)

Well, if you forget - I will do it myself .

## License 

The module is provided under a [MIT (Expat)](https://raw.github.com/Meettya/multiversed/master/LICENSE) license.

