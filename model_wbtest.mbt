///|
test "train duplicate-x empirical model and copy safety" {
  let m = train_l2([sample(0.0, 1.0), sample(0.0, 3.0), sample(1.0, 0.0)]).unwrap()
  assert_eq(m.knots[0].y, 4.0 / 3.0)
  assert_eq(m.knots[1].y, 4.0 / 3.0)
  let c = copy_model(m).unwrap()
  c.knots[0] = { x: -1.0, y: -1.0, weight: 1.0, }
  assert_eq(m.knots[0].x, 0.0)
  assert_true(
    validate_model({ knots: [], direction: Increasing, loss: Squared, })
    is Err(_),
  )
}
