###
v.0.0.0.12
###

xyz = ->
	'xyz'

baz = ->
	'baz`'

with_external = (name) ->
	@external_fn(name)

version = '0.0.0-12'

int_0_0_0_12 = ->
  'int_0_0_0_12'

module.exports = {
	xyz
	baz
	with_external
	version
	int_0_0_0_12
}