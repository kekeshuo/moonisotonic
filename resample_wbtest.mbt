///|
test "resampling is fully caller-controlled and rejects invalid plans" {
  let s = [sample(0.0, 0.0), sample(1.0, 2.0)]
  let r = resample_sensitivity(s, [[0, 1], [0, 0], [1, 1]], [0.5]).unwrap()
  assert_eq(r.lower, [0.0])
  assert_eq(r.median, [1.0])
  assert_eq(r.upper, [2.0])
  assert_eq(r.fits, 3)
  assert_true(resample_sensitivity(s, [[2]], [0.5]) is Err(_))
}
