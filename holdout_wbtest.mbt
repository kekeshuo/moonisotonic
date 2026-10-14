///|
test "holdout leakage is rejected and evaluation stays out of sample" {
  let s = [sample(0.0, 0.0), sample(1.0, 1.0), sample(0.5, 1.0)]
  let h = holdout(s, [0, 1], [2]).unwrap()
  assert_eq(h.training.mse, 0.0)
  assert_eq(h.validation.mse, 0.25)
  assert_eq(compare_calibration(s, h).unwrap().brier_change, 0.0)
  assert_true(holdout(s, [0, 1], [1, 2]) is Err(_))
  assert_true(holdout(s, [0, 0], [2]) is Err(_))
}
