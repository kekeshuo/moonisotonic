///|
pub(all) struct OrderAudit {
  violations : Array[Int]
  largest_drop : Double
  total_drop : Double
  plateaus : Int
} derive(Debug)

///|
pub fn audit_order(
  values : Array[Double],
  direction? : Direction = Increasing,
  tolerance? : Double = 0.0,
) -> Result[OrderAudit, String] {
  if !finite(tolerance) || tolerance < 0.0 {
    return Err("invalid tolerance")
  }
  let violations = []
  let mut largest_drop = 0.0
  let mut total_drop = 0.0
  let mut plateaus = 0
  for i = 0; i < values.length(); i = i + 1 {
    if !finite(values[i]) {
      return Err("nonfinite value")
    }
    if i > 0 {
      let drop = match direction {
        Increasing => values[i - 1] - values[i]
        Decreasing => values[i] - values[i - 1]
      }
      if !finite(drop) {
        return Err("difference overflow")
      }
      if drop > tolerance {
        violations.push(i)
        total_drop = total_drop + drop
        if drop > largest_drop {
          largest_drop = drop
        }
      }
      if drop.abs() <= tolerance {
        plateaus = plateaus + 1
      }
    }
  }
  if !finite(total_drop) {
    return Err("drop sum overflow")
  }
  Ok({ violations, largest_drop, total_drop, plateaus, })
}

///|
pub(all) struct ProjectionAudit {
  residual_sum : Double
  min_prefix : Double
  max_prefix : Double
  max_block_balance : Double
  order : OrderAudit
} derive(Debug)

///|
/// L2 chain optimality diagnostics. Increasing fits have nonpositive residual prefixes.
pub fn audit_projection(
  y : Array[Double],
  weights : Array[Double],
  fit : Fit,
) -> Result[ProjectionAudit, String] {
  match validate_series(y, weights) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  if fit.values.length() != y.length() {
    return Err("fit length mismatch")
  }
  match expand_blocks(fit.blocks, y.length()) {
    Err(e) => return Err(e)
    Ok(v) => if v != fit.values { return Err("fit partition mismatch") }
  }
  let order = match audit_order(fit.values, direction=fit.direction) {
    Err(e) => return Err(e)
    Ok(v) => v
  }
  let mut residual_sum = 0.0
  let mut min_prefix = 0.0
  let mut max_prefix = 0.0
  let mut max_block_balance = 0.0
  for block in fit.blocks {
    let mut balance = 0.0
    for i = block.start; i < block.end; i = i + 1 {
      let residual = weights[i] * (fit.values[i] - y[i])
      balance = balance + residual
      residual_sum = residual_sum + residual
      if !finite(residual_sum) || !finite(balance) {
        return Err("residual overflow")
      }
      if residual_sum < min_prefix {
        min_prefix = residual_sum
      }
      if residual_sum > max_prefix {
        max_prefix = residual_sum
      }
    }
    if balance.abs() > max_block_balance {
      max_block_balance = balance.abs()
    }
  }
  Ok({ residual_sum, min_prefix, max_prefix, max_block_balance, order, })
}

///|
#deprecated
pub extend OrderAudit with @debug.Debug::{to_repr}

///|
#deprecated
pub extend ProjectionAudit with @debug.Debug::{to_repr}
