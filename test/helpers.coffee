module 'helpers'
helpers = myproject.helpers

test 'add', ->
  equal helpers.add(2, 4), 6, 'Simple addition'
  equal helpers.add(-2, -4), -6, 'Negative numbers'

test 'multiply', ->
  equal helpers.multiply(2, 4), 8, 'Multiplication'
  # Fail on purpose
  equal helpers.multiply(2, 0), 2, 'Multiply by zero'

test 'square', ->
  equal helpers.square(3), 9, 'Squaring'
  equal helpers.square(-3), 9, 'Negative number'
