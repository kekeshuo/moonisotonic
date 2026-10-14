///|
test "pointwise intervals and infeasibility" {
  let f = fit_bounded([4.0, 1.0, 9.0], [1.0, 1.0, 1.0], [0.0, 2.0, 3.0], [
    3.0, 3.0, 4.0,
  ]).unwrap()
  assert_eq(f.values, [2.5, 2.5, 4.0])
  assert_true(check_bounds([4.0, 0.0], [5.0, 3.0]) is Err(_))
  assert_eq(
    fit_range([0.0, 2.0, 3.0], [1.0, 1.0, 1.0], 0.0, 1.0).unwrap().values,
    [0.0, 1.0, 1.0],
  )
  assert_eq(
    fit_range([0.0, 2.0], [1.0, 1.0], 0.0, 1.0, direction=Decreasing).unwrap().values,
    [1.0, 1.0],
  )
}
