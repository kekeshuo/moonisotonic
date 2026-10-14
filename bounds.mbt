///|
priv struct BoundPool {
  start : Int
  end : Int
  weight : Double
  mean : Double
  lower : Double
  upper : Double
  value : Double
}

///|
fn clip(value : Double, lower : Double, upper : Double) -> Double {
  if value < lower {
    lower
  } else if value > upper {
    upper
  } else {
    value
  }
}

///|
pub fn check_bounds(
  lower : Array[Double],
  upper : Array[Double],
  direction? : Direction = Increasing,
) -> Result[Unit, String] {
  if lower.length() == 0 || lower.length() != upper.length() {
    return Err("bound length mismatch or empty bounds")
  }
  let mut frontier = match direction {
    Increasing => lower[0]
    Decreasing => upper[0]
  }
  for i = 0; i < lower.length(); i = i + 1 {
    if !finite(lower[i]) || !finite(upper[i]) || lower[i] > upper[i] {
      return Err("invalid interval")
    }
    match direction {
      Increasing => {
        if lower[i] > frontier {
          frontier = lower[i]
        }
        if frontier > upper[i] {
          return Err("infeasible increasing bounds")
        }
      }
      Decreasing => {
        if upper[i] < frontier {
          frontier = upper[i]
        }
        if frontier < lower[i] {
          return Err("infeasible decreasing bounds")
        }
      }
    }
  }
  Ok(())
}

///|
/// Exact L2 chain fit within individual finite intervals.
pub fn fit_bounded(
  y : Array[Double],
  weights : Array[Double],
  lower : Array[Double],
  upper : Array[Double],
  direction? : Direction = Increasing,
) -> Result[Fit, String] {
  match validate_series(y, weights) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  if lower.length() != y.length() {
    return Err("bound length mismatch")
  }
  match check_bounds(lower, upper, direction~) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  let sign = match direction {
    Increasing => 1.0
    Decreasing => -1.0
  }
  let pools : Array[BoundPool] = []
  for i = 0; i < y.length(); i = i + 1 {
    let lo = if sign > 0.0 { lower[i] } else { -upper[i] }
    let hi = if sign > 0.0 { upper[i] } else { -lower[i] }
    pools.push({
      start: i,
      end: i + 1,
      weight: weights[i],
      mean: sign * y[i],
      lower: lo,
      upper: hi,
      value: clip(sign * y[i], lo, hi),
    })
    while pools.length() >= 2 {
      let n = pools.length()
      let a = pools[n - 2]
      let b = pools[n - 1]
      if a.value < b.value {
        break
      }
      let lo = if a.lower > b.lower { a.lower } else { b.lower }
      let hi = if a.upper < b.upper { a.upper } else { b.upper }
      if lo > hi {
        return Err("infeasible pooled interval")
      }
      let weight = a.weight + b.weight
      let mean = a.mean * (a.weight / weight) + b.mean * (b.weight / weight)
      if !finite(mean) {
        return Err("bounded mean overflow")
      }
      ignore(pools.pop())
      pools[n - 2] = {
        start: a.start,
        end: b.end,
        weight,
        mean,
        lower: lo,
        upper: hi,
        value: clip(mean, lo, hi),
      }
    }
  }
  let blocks = pools.map(fn(p) {
    { start: p.start, end: p.end, weight: p.weight, value: sign * p.value, }
  })
  let values = match expand_blocks(blocks, y.length()) {
    Err(e) => return Err(e)
    Ok(v) => v
  }
  match squared_loss(y, values, weights) {
    Err(e) => Err(e)
    Ok(objective) => Ok({ values, blocks, objective, direction, })
  }
}

///|
pub fn fit_range(
  y : Array[Double],
  weights : Array[Double],
  lower : Double,
  upper : Double,
  direction? : Direction = Increasing,
) -> Result[Fit, String] {
  fit_bounded(
    y,
    weights,
    Array::make(y.length(), lower),
    Array::make(y.length(), upper),
    direction~,
  )
}
