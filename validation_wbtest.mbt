///|
test "input contracts reject zero weights and empty data" {
  assert_true(validate_series([], []) is Err(_))
  assert_true(validate_series([1.0], [0.0]) is Err(_))
  assert_true(validate_series([1.0], [1.0, 2.0]) is Err(_))
  assert_eq(sample(2.0, 3.0).weight, 1.0)
  assert_true(validate_samples([sample(2.0, 3.0)]) is Ok(_))
}
