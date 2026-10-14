///|
test "quantile envelope is empirical not a confidence interval" {
  let s = [
    sample(0.0, 0.0),
    sample(0.0, 1.0),
    sample(0.0, 2.0),
    sample(1.0, 3.0),
  ]
  let b = train_band(s, 0.1, 0.9).unwrap()
  let r = predict_band(b, [0.0]).unwrap()[0]
  assert_eq(r.lower, 0.0)
  assert_eq(r.upper, 2.0)
  assert_eq(band_coverage(b, s).unwrap().coverage, 1.0)
  assert_true(train_band(s, 0.9, 0.1) is Err(_))
}
