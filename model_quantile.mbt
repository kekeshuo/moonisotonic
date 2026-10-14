///|
/// Fit grouped coordinates from raw replicates, not their arithmetic means.
pub fn train_quantile(
  samples : Array[Sample],
  tau : Double,
  direction? : Direction = Increasing,
) -> Result[Model, String] {
  if !finite(tau) || tau <= 0.0 || tau >= 1.0 {
    return Err("fitting quantile must be in (0,1)")
  }
  let p = match prepare(samples) {
    Err(e) => return Err(e)
    Ok(v) => v
  }
  let y = p.samples.map(fn(s) { s.y })
  let weights = p.samples.map(fn(s) { s.weight })
  let blocks : Array[Block] = []
  for i = 0; i < p.coordinates.length(); i = i + 1 {
    let start = p.offsets[i]
    let end = p.offsets[i + 1]
    let value = match block_quantile(y, weights, start, end, tau) {
      Err(e) => return Err(e)
      Ok(v) => v
    }
    blocks.push({ start, end, weight: p.weights[i], value, })
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
  let fitted = match expand_blocks(blocks, y.length()) {
    Err(e) => return Err(e)
    Ok(v) => v
  }
  let knots : Array[Knot] = []
  for i = 0; i < p.coordinates.length(); i = i + 1 {
    knots.push({
      x: p.coordinates[i],
      y: fitted[p.offsets[i]],
      weight: p.weights[i],
    })
  }
  Ok({ knots, direction, loss: Quantile(tau), })
}

///|
pub fn train_l1(
  samples : Array[Sample],
  direction? : Direction = Increasing,
) -> Result[Model, String] {
  match train_quantile(samples, 0.5, direction~) {
    Err(e) => Err(e)
    Ok(model) => Ok({ ..model, loss: Absolute, })
  }
}

///|
pub fn train(
  samples : Array[Sample],
  loss? : Loss = Squared,
  direction? : Direction = Increasing,
) -> Result[Model, String] {
  match loss {
    Squared => train_l2(samples, direction~)
    Absolute => train_l1(samples, direction~)
    Quantile(tau) => train_quantile(samples, tau, direction~)
  }
}
