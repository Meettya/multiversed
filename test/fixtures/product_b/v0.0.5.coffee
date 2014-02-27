###

  v0.0.5

###

foo = -> 'foo`'

dev = (a, b) ->
  a / b

version = '0.0.5'

get_version = (prefix) ->
  "#{prefix} - #{@version}"

get_elements_count = ->
  @_element_count_

module.exports = {
  foo
  dev
  version
  get_version
  get_elements_count
}