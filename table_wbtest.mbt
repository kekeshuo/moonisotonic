///|
test "numeric TSV contracts and roundtrip" {
  let input = "x\ty\tweight\n0\t1\t1\n2\t3\t2\n"
  let s = read_samples(input).unwrap()
  assert_eq(s.length(), 2)
  assert_eq(read_samples(write_samples(s).unwrap()).unwrap()[1].weight, 2.0)
  assert_true(read_samples(input, max_rows=1) is Err(_))
  assert_true(read_samples("x\ty\tweight\n0\tNaN\t1") is Err(_))
  assert_true(read_samples("x\ty\tweight\n0\t1\t0") is Err(_))
  assert_true(
    write_predictions(s, train_l2(s).unwrap()).unwrap().contains("prediction"),
  )
}
