///|
test "cross-validation covers each row once with held-out interpolation" {
  let s = [
    sample(0.0, 0.0),
    sample(1.0, 1.0),
    sample(2.0, 2.0),
    sample(3.0, 3.0),
  ]
  let c = cross_validate(s, [0, 1, 0, 1], 2).unwrap()
  assert_eq(c.predictions, [1.0, 1.0, 2.0, 2.0])
  assert_eq(c.aggregate.mse, 0.5)
  assert_eq(contiguous_folds(5, 2).unwrap(), [0, 0, 0, 1, 1])
  assert_true(cross_validate(s, [0, 0, 0, 0], 2) is Err(_))
}
