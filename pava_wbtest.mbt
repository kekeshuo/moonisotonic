///|
test "weighted pooling and antitonic fit" {
  let f = fit_l2([3.0, 1.0, 5.0], [1.0, 3.0, 1.0]).unwrap()
  assert_eq(f.values, [1.5, 1.5, 5.0])
  assert_eq(f.objective, 3.0)
  assert_eq(expand_blocks(f.blocks, 3).unwrap(), f.values)
  assert_eq(isotonic([1.0, 3.0, 2.0], direction=Decreasing).unwrap().values, [
    2.0, 2.0, 2.0,
  ])
  assert_true(expand_blocks(f.blocks, 4) is Err(_))
}
