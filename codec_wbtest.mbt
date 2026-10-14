///|
test "JSON roundtrip schema rejection and budgets" {
  let m = train_l2([sample(0.0, 1.0), sample(2.0, 3.0)]).unwrap()
  let encoded = encode_model(m).unwrap()
  let loaded = decode_model(encoded).unwrap()
  assert_eq(predict(loaded, 1.0).unwrap(), 2.0)
  assert_true(decode_model(encoded, max_knots=1) is Err(_))
  assert_true(decode_model("[]") is Err(_))
  assert_true(decode_model("not json") is Err(_))
}
