///|
test "lower median pooling resists an outlier" {
  assert_eq(weighted_quantile([9.0, 1.0], [1.0, 1.0], 0.5).unwrap(), 1.0)
  assert_eq(fit_l1([3.0, 1.0, 100.0], [1.0, 1.0, 1.0]).unwrap().values, [
    1.0, 1.0, 100.0,
  ])
  assert_eq(fit_quantile([3.0, 1.0], [1.0, 1.0], 0.75).unwrap().values, [
    3.0, 3.0,
  ])
  assert_true(fit_quantile([1.0], [1.0], 1.0) is Err(_))
}
