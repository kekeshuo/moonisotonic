///|
pub(all) enum Loss {
  Squared
  Absolute
  Quantile(Double)
} derive(Debug)

///|
pub(all) struct Knot {
  x : Double
  y : Double
  weight : Double
} derive(Debug)

///|
pub(all) struct Model {
  knots : Array[Knot]
  direction : Direction
  loss : Loss
} derive(Debug)

///|
pub fn validate_model(model : Model) -> Result[Unit, String] {
  if model.knots.length() == 0 {
    return Err("empty model")
  }
  match model.loss {
    Quantile(tau) =>
      if !finite(tau) || tau <= 0.0 || tau >= 1.0 {
        return Err("invalid model quantile")
      }
    _ => ()
  }
  for i = 0; i < model.knots.length(); i = i + 1 {
    let k = model.knots[i]
    if !finite(k.x) || !finite(k.y) || !finite(k.weight) || k.weight <= 0.0 {
      return Err("invalid knot")
    }
    if i > 0 {
      let previous = model.knots[i - 1]
      if previous.x >= k.x {
        return Err("coordinates must be strictly increasing")
      }
      if !before(previous.y, k.y, model.direction) {
        return Err("nonmonotone model")
      }
    }
  }
  Ok(())
}

///|
/// L2 empirical calibration. Repeated x values are constrained to one fitted y.
pub fn train_l2(
  samples : Array[Sample],
  direction? : Direction = Increasing,
) -> Result[Model, String] {
  let p = match prepare(samples) {
    Err(e) => return Err(e)
    Ok(v) => v
  }
  let fit = match fit_l2(p.means, p.weights, direction~) {
    Err(e) => return Err(e)
    Ok(v) => v
  }
  let knots : Array[Knot] = []
  for i = 0; i < p.coordinates.length(); i = i + 1 {
    knots.push({ x: p.coordinates[i], y: fit.values[i], weight: p.weights[i], })
  }
  Ok({ knots, direction, loss: Squared, })
}

///|
/// Safe model copying for consumers retaining independently mutable arrays.
pub fn copy_model(model : Model) -> Result[Model, String] {
  match validate_model(model) {
    Err(e) => Err(e)
    Ok(_) => Ok({ ..model, knots: model.knots.copy(), })
  }
}

///|
pub fn knot_arrays(
  model : Model,
) -> Result[(Array[Double], Array[Double]), String] {
  match validate_model(model) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  Ok((model.knots.map(fn(k) { k.x }), model.knots.map(fn(k) { k.y })))
}

///|
#deprecated
pub extend Loss with @debug.Debug::{to_repr}

///|
#deprecated
pub extend Knot with @debug.Debug::{to_repr}

///|
#deprecated
pub extend Model with @debug.Debug::{to_repr}
