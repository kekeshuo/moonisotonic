///|
/// Lower weighted quantile, including deterministic endpoint and tie semantics.
pub fn weighted_quantile(
  y : Array[Double],
  weights : Array[Double],
  tau : Double,
) -> Result[Double, String] {
  match validate_series(y, weights) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  if !finite(tau) || tau < 0.0 || tau > 1.0 {
    return Err("quantile outside [0,1]")
  }
  let order : Array[(Double, Double)] = []
  let mut total = 0.0
  for i = 0; i < y.length(); i = i + 1 {
    order.push((y[i], weights[i]))
    total = total + weights[i]
  }
  order.sort_by(fn(a, b) { a.0.compare(b.0) })
  let target = tau * total
  let mut cumulative = 0.0
  for pair in order {
    cumulative = cumulative + pair.1
    if cumulative >= target {
      return Ok(pair.0)
    }
  }
  Ok(order[order.length() - 1].0)
}

///|
fn block_quantile(
  y : Array[Double],
  weights : Array[Double],
  start : Int,
  end : Int,
  tau : Double,
) -> Result[Double, String] {
  let values = []
  let w = []
  for i = start; i < end; i = i + 1 {
    values.push(y[i])
    w.push(weights[i])
  }
  weighted_quantile(values, w, tau)
}

///|
pub fn pinball_loss(
  y : Array[Double],
  values : Array[Double],
  weights : Array[Double],
  tau : Double,
) -> Result[Double, String] {
  match validate_series(y, weights) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  if values.length() != y.length() {
    return Err("prediction length mismatch")
  }
  if !finite(tau) || tau < 0.0 || tau > 1.0 {
    return Err("quantile outside [0,1]")
  }
  let mut loss = 0.0
  for i = 0; i < y.length(); i = i + 1 {
    if !finite(values[i]) {
      return Err("nonfinite prediction")
    }
    let residual = y[i] - values[i]
    let term = if residual >= 0.0 {
      tau * residual
    } else {
      (tau - 1.0) * residual
    }
    loss = loss + weights[i] * term
    if !finite(loss) {
      return Err("pinball objective overflow")
    }
  }
  Ok(loss)
}

///|
/// Generalized PAVA with canonical lower minimizers. Sorting pooled blocks is deliberately simple, not linear-time.
pub fn fit_quantile(
  y : Array[Double],
  weights : Array[Double],
  tau : Double,
  direction? : Direction = Increasing,
) -> Result[Fit, String] {
  match validate_series(y, weights) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  if !finite(tau) || tau <= 0.0 || tau >= 1.0 {
    return Err("fitting quantile must be in (0,1)")
  }
  let blocks : Array[Block] = []
  for i = 0; i < y.length(); i = i + 1 {
    blocks.push({ start: i, end: i + 1, weight: weights[i], value: y[i], })
    while blocks.length() >= 2 {
      let n = blocks.length()
      let a = blocks[n - 2]
      let b = blocks[n - 1]
      if before(a.value, b.value, direction) && a.value != b.value {
        break
      }
      let value = match block_quantile(y, weights, a.start, b.end, tau) {
        Err(e) => return Err(e)
        Ok(v) => v
      }
      ignore(blocks.pop())
      blocks[n - 2] = {
        start: a.start,
        end: b.end,
        weight: a.weight + b.weight,
        value,
      }
    }
  }
  let values = match expand_blocks(blocks, y.length()) {
    Err(e) => return Err(e)
    Ok(v) => v
  }
  match pinball_loss(y, values, weights, tau) {
    Err(e) => Err(e)
    Ok(objective) => Ok({ values, blocks, objective, direction, })
  }
}

///|
/// Absolute-error isotonic regression. Objective is L1, not half-L1 pinball loss.
pub fn fit_l1(
  y : Array[Double],
  weights : Array[Double],
  direction? : Direction = Increasing,
) -> Result[Fit, String] {
  match fit_quantile(y, weights, 0.5, direction~) {
    Err(e) => Err(e)
    Ok(fit) => {
      let objective = fit.objective * 2.0
      if !finite(objective) {
        return Err("L1 objective overflow")
      }
      Ok({ ..fit, objective, })
    }
  }
}
