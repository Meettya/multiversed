###

  v0.0.8

###

{ get_version } = require './v0.0.4'

version = '0.0.8'

available_test = ->
  'existing method'     : @isCommandExists 'multiple_elements_count_by'
  'non-existing method' : @isCommandExists 'sdkjgskdjgdskgdskj'

module.exports = {
  version
  get_version
  available_test
}