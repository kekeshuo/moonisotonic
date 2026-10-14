///|
/// Weighted least-squares projection onto a chain. Input order is significant.
pub fn fit_l2(
  y : Array[Double],
  weights : Array[Double],
  direction? : Direction = Increasing,
) -> Result[Fit, String] {
  match validate_series(y, weights) {
    Err(e) => return Err(e)
    Ok(_) => ()
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
      let weight = a.weight + b.weight
      let value = a.value * (a.weight / weight) + b.value * (b.weight / weight)
      if !finite(weight) || !finite(value) {
        return Err("pooled mean overflow")
      }
      ignore(blocks.pop())
      blocks[n - 2] = { start: a.start, end: b.end, weight, value, }
    }
  }
  let values = Array::make(y.length(), 0.0)
  for block in blocks {
    for i = block.start; i < block.end; i = i + 1 {
      values[i] = block.value
    }
  }
  match squared_loss(y, values, weights) {
    Err(e) => Err(e)
    Ok(objective) => Ok({ values, blocks, objective, direction, })
  }
}

///|
/// Equal-weight convenience API. Does not sort observations.
pub fn isotonic(
  y : Array[Double],
  direction? : Direction = Increasing,
) -> Result[Fit, String] {
  fit_l2(y, Array::make(y.length(), 1.0), direction~)
}

///|
/// Expand a partition into fitted observations, rejecting inconsistent coverage.
pub fn expand_blocks(
  blocks : Array[Block],
  size : Int,
) -> Result[Array[Double], String] {
  if size <= 0 {
    return Err("nonpositive size")
  }
  let values = Array::make(size, 0.0)
  let mut next = 0
  for block in blocks {
    if block.start != next || block.end <= block.start || block.end > size {
      return Err("blocks must partition the requested size")
    }
    if !finite(block.value) || !finite(block.weight) || block.weight <= 0.0 {
      return Err("invalid block statistics")
    }
    for i = block.start; i < block.end; i = i + 1 {
      values[i] = block.value
    }
    next = block.end
  }
  if next != size {
    return Err("incomplete partition")
  }
  Ok(values)
}
