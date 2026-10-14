///|
test "raw duplicate quantiles differ from averaging replicates" {
  let s = [
    sample(0.0, 0.0),
    sample(0.0, 0.0),
    sample(0.0, 100.0),
    sample(1.0, 10.0),
  ]
  assert_eq(train_l1(s).unwrap().knots[0].y, 0.0)
  assert_eq(train_quantile(s, 0.9).unwrap().knots[0].y, 100.0)
  assert_eq(train_quantile(s, 0.9).unwrap().knots[1].y, 100.0)
  assert_eq(train(s, loss=Absolute).unwrap().knots[1].y, 10.0)
}
