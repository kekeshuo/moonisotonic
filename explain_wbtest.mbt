///|
test "pooling explanation preserves error and provenance" {
  let y = [3.0, 1.0, 5.0]
  let w = [1.0, 3.0, 1.0]
  let f = fit_l2(y, w).unwrap()
  let e = explain_fit(y, w, f).unwrap()
  assert_eq(e[0].observed_mean, 1.5)
  assert_eq(e[0].observed_min, 1.0)
  assert_eq(e[0].observed_max, 3.0)
  assert_eq(e[0].squared_error, 3.0)
  assert_true(explanation_table(e).contains("squared_error"))
}
