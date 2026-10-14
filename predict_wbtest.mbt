///|
test "interpolation boundaries and singleton model" {
  let m = train_l2([sample(0.0, 0.0), sample(2.0, 4.0)]).unwrap()
  assert_eq(predict_many(m, [-1.0, 1.0, 3.0]).unwrap(), [0.0, 2.0, 4.0])
  assert_eq(predict(m, 1.0, interpolation=Previous).unwrap(), 0.0)
  assert_eq(predict(m, 1.0, interpolation=Next).unwrap(), 4.0)
  assert_eq(predict(m, 3.0, boundary=Extend).unwrap(), 6.0)
  assert_true(predict(m, -1.0, boundary=Reject) is Err(_))
  assert_eq(predict(train_l2([sample(1.0, 7.0)]).unwrap(), 99.0).unwrap(), 7.0)
}
