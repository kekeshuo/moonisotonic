///|
test "weighted reliability endpoint and empty bin behavior" {
  let r = reliability([0.0, 1.0], [0.0, 1.0], [1.0, 2.0], bin_count=4).unwrap()
  assert_eq(r.bins.length(), 2)
  assert_eq(r.bins[1].index, 3)
  assert_eq(r.brier, 0.0)
  assert_eq(r.ece, 0.0)
  assert_true(reliability([1.0], [1.1], [1.0]) is Err(_))
  assert_true(train_probability([sample(0.0, 2.0)]) is Err(_))
}
