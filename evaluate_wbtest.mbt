///|
test "weighted evaluation distinguishes normalized losses" {
  let e = evaluate_predictions([1.0, 3.0], [2.0, 2.0], [1.0, 3.0]).unwrap()
  assert_eq(e.mse, 1.0)
  assert_eq(e.mae, 1.0)
  assert_eq(e.bias, -0.5)
  assert_eq(e.weight, 4.0)
  assert_eq(
    evaluate_predictions([0.0], [2.0], [1.0], loss=Quantile(0.25)).unwrap().loss,
    1.5,
  )
  assert_eq(evaluation_lines(e).length(), 7)
}
