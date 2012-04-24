module 'myproject'

test 'Helper Functions', ->
  helpers = myproject.helpers
  equal helpers.add(2, 4), 6, 'Addition'
  equal helpers.multiply(2, 4), 8, 'Multiplication'
  equal helpers.square(3), 9, 'Squaring'
