///|
test "public consumer model validation and mutation isolation" {
  let model = @moonisotonic.train_l2([
    @moonisotonic.sample(0.0, 0.0),
    @moonisotonic.sample(1.0, 1.0),
  ]).unwrap()
  let copied = @moonisotonic.copy_model(model).unwrap()
  model.knots[0] = { x: 2.0, y: 0.0, weight: 1.0, }
  assert_true(@moonisotonic.predict(model, 0.0) is Err(_))
  assert_eq(@moonisotonic.predict(copied, 0.5).unwrap(), 0.5)
  assert_true(@moonisotonic.decode_model("[]") is Err(_))
  let encoded = @moonisotonic.encode_model(copied).unwrap()
  assert_true(@moonisotonic.decode_model(encoded, max_knots=1) is Err(_))
}

///|
test "public consumer malformed workflows fail without panics" {
  let rows = [@moonisotonic.sample(0.0, 0.0), @moonisotonic.sample(1.0, 1.0)]
  assert_true(@moonisotonic.holdout(rows, [0], [0]) is Err(_))
  assert_true(@moonisotonic.cross_validate(rows, [0, 0], 2) is Err(_))
  assert_true(@moonisotonic.read_samples("x\ty\tweight\n0\t1\t0") is Err(_))
  assert_true(@moonisotonic.train_quantile(rows, 0.0) is Err(_))
  assert_true(@moonisotonic.train_quantile(rows, 1.0) is Err(_))
  assert_true(
    @moonisotonic.train_probability([@moonisotonic.sample(0.0, 2.0)]) is Err(_),
  )
  assert_true(@moonisotonic.train_band(rows, 0.75, 0.25) is Err(_))
  assert_true(@moonisotonic.resample_sensitivity(rows, [[2]], [0.0]) is Err(_))
}

///|
test "public weighted transformation and duplicate quantile properties" {
  let y = [3.0, 1.0, 2.0]
  let w = [1.0, 2.0, 1.0]
  let a = @moonisotonic.fit_l2(y, w).unwrap()
  let b = @moonisotonic.fit_l2(
    y.map(fn(v) { 2.0 * v + 4.0 }),
    w.map(fn(v) { 3.0 * v }),
  ).unwrap()
  for i = 0; i < y.length(); i = i + 1 {
    assert_true((b.values[i] - (2.0 * a.values[i] + 4.0)).abs() < 1.0e-9)
  }
  let model = @moonisotonic.train_quantile(
    [
      @moonisotonic.sample(1.0, 0.0),
      @moonisotonic.sample(1.0, 100.0),
      @moonisotonic.sample(2.0, 100.0),
    ],
    0.25,
  ).unwrap()
  assert_eq(@moonisotonic.predict(model, 1.0).unwrap(), 0.0)
}
