///|
test "plateaus inverse endpoints and decreasing tables" {
  let m = train_l2([
    sample(0.0, 0.0),
    sample(1.0, 2.0),
    sample(2.0, 2.0),
    sample(3.0, 4.0),
  ]).unwrap()
  let r = inverse(m, 2.0).unwrap()
  assert_eq(r.lower, 1.0)
  assert_eq(r.upper, 2.0)
  assert_eq(inverse(m, 1.0).unwrap().lower, 0.5)
  assert_eq(threshold_domain(m, 2.0).unwrap().upper, 3.0)
  assert_true(inverse(m, 5.0) is Err(_))
  let d = train_l2([sample(0.0, 4.0), sample(2.0, 0.0)], direction=Decreasing).unwrap()
  assert_eq(inverse(d, 2.0).unwrap().lower, 1.0)
}
