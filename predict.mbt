///|
pub(all) enum Interpolation {
  Linear
  Previous
  Next
} derive(Debug)

///|
pub(all) enum Boundary {
  Clamp
  Reject
  Extend
} derive(Debug)

///|
fn interpolate(
  a : Knot,
  b : Knot,
  x : Double,
  interpolation : Interpolation,
) -> Result[Double, String] {
  if x == a.x {
    return Ok(a.y)
  }
  if x == b.x {
    return Ok(b.y)
  }
  match interpolation {
    Previous => Ok(a.y)
    Next => Ok(b.y)
    Linear => {
      let width = b.x - a.x
      let offset = x - a.x
      if !finite(width) || !finite(offset) || width <= 0.0 {
        return Err("coordinate span overflow")
      }
      let ratio = offset / width
      let value = a.y * (1.0 - ratio) + b.y * ratio
      if !finite(value) {
        Err("interpolation overflow")
      } else {
        Ok(value)
      }
    }
  }
}

///|
fn predict_valid(
  model : Model,
  x : Double,
  interpolation : Interpolation,
  boundary : Boundary,
) -> Result[Double, String] {
  if !finite(x) {
    return Err("nonfinite query")
  }
  let n = model.knots.length()
  let first = model.knots[0]
  let last = model.knots[n - 1]
  if x < first.x || x > last.x {
    match boundary {
      Reject => return Err("query outside training domain")
      Clamp => return Ok(if x < first.x { first.y } else { last.y })
      Extend => {
        if n == 1 {
          return Ok(first.y)
        }
        return if x < first.x {
          interpolate(first, model.knots[1], x, Linear)
        } else {
          interpolate(model.knots[n - 2], last, x, Linear)
        }
      }
    }
  }
  if n == 1 || x == last.x {
    return Ok(last.y)
  }
  let mut lo = 0
  let mut hi = n - 1
  while hi - lo > 1 {
    let mid = lo + (hi - lo) / 2
    if model.knots[mid].x <= x {
      lo = mid
    } else {
      hi = mid
    }
  }
  interpolate(model.knots[lo], model.knots[hi], x, interpolation)
}

///|
pub fn predict(
  model : Model,
  x : Double,
  interpolation? : Interpolation = Linear,
  boundary? : Boundary = Clamp,
) -> Result[Double, String] {
  match validate_model(model) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  predict_valid(model, x, interpolation, boundary)
}

///|
/// Validate once per batch, then locate each query by binary search.
pub fn predict_many(
  model : Model,
  queries : Array[Double],
  interpolation? : Interpolation = Linear,
  boundary? : Boundary = Clamp,
) -> Result[Array[Double], String] {
  match validate_model(model) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  let values = []
  for x in queries {
    match predict_valid(model, x, interpolation, boundary) {
      Err(e) => return Err(e)
      Ok(value) => values.push(value)
    }
  }
  Ok(values)
}

///|
pub fn domain(model : Model) -> Result[(Double, Double), String] {
  match validate_model(model) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  Ok((model.knots[0].x, model.knots[model.knots.length() - 1].x))
}

///|
#deprecated
pub extend Interpolation with @debug.Debug::{to_repr}

///|
#deprecated
pub extend Boundary with @debug.Debug::{to_repr}
