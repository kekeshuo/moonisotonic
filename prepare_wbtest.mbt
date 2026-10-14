///|
test "duplicates stable sorting and original-order restoration" {
  let p = prepare([
    sample(2.0, 7.0),
    sample(1.0, 1.0),
    sample(1.0, 3.0, weight=3.0),
  ]).unwrap()
  assert_eq(p.means, [2.5, 7.0])
  assert_eq(p.weights, [4.0, 1.0])
  assert_eq(p.offsets, [0, 2, 3])
  assert_eq(group_replication_counts(p).unwrap(), [2, 1])
  assert_eq(restore_order([2.5, 2.5, 7.0], p.original_indices).unwrap(), [
    7.0, 2.5, 2.5,
  ])
  assert_true(restore_order([1.0, 2.0], [0, 0]) is Err(_))
}
