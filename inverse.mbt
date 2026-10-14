///|
pub(all) struct InverseRange {
  lower : Double
  upper : Double
} derive(Debug)

///|
/// Preimage under linear interpolation, restricted to the training domain.
pub fn inverse(model : Model, target : Double) -> Result[InverseRange, String] {
  match validate_model(model) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  if !finite(target) {
    return Err("nonfinite inverse target")
  }
  let first = model.knots[0]
  let last = model.knots[model.knots.length() - 1]
  if !before(first.y, target, model.direction) ||
    !before(target, last.y, model.direction) {
    return Err("target outside fitted range")
  }
  let mut lower : Double? = None
  let mut upper : Double? = None
  for i = 0; i < model.knots.length(); i = i + 1 {
    let k = model.knots[i]
    if k.y == target {
      if lower is None {
        lower = Some(k.x)
      }
      upper = Some(k.x)
    }
    if i > 0 {
      let previous = model.knots[i - 1]
      if previous.y != k.y &&
        before(previous.y, target, model.direction) &&
        before(target, k.y, model.direction) {
        let denominator = k.y - previous.y
        let numerator = target - previous.y
        if !finite(denominator) || !finite(numerator) {
          return Err("inverse span overflow")
        }
        let ratio = numerator / denominator
        let x = previous.x * (1.0 - ratio) + k.x * ratio
        if !finite(x) {
          return Err("inverse coordinate overflow")
        }
        if lower is None {
          lower = Some(x)
        }
        upper = Some(x)
      }
    }
  }
  match (lower, upper) {
    (Some(lower), Some(upper)) => Ok({ lower, upper, })
    _ => Err("no inverse in training domain")
  }
}

///|
pub fn threshold_domain(
  model : Model,
  target : Double,
  above? : Bool = true,
) -> Result[InverseRange, String] {
  let cut = match inverse(model, target) {
    Err(e) => return Err(e)
    Ok(v) => v
  }
  let ends = match domain(model) {
    Err(e) => return Err(e)
    Ok(v) => v
  }
  match (model.direction, above) {
    (Increasing, true) | (Decreasing, false) =>
      Ok({ lower: cut.lower, upper: ends.1, })
    _ => Ok({ lower: ends.0, upper: cut.upper, })
  }
}

///|
#deprecated
pub extend InverseRange with @debug.Debug::{to_repr}
