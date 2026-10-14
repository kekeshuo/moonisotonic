///|
test "order audit and KKT prefix balance" {
  let y = [3.0, 1.0, 4.0]
  let w = [1.0, 1.0, 1.0]
  let f = fit_l2(y, w).unwrap()
  let a = audit_projection(y, w, f).unwrap()
  assert_eq(a.residual_sum, 0.0)
  assert_eq(a.min_prefix, -1.0)
  assert_eq(a.max_prefix, 0.0)
  assert_eq(a.max_block_balance, 0.0)
  assert_eq(audit_order(y).unwrap().violations, [1])
}
