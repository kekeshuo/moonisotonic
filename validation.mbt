///|
pub(all) enum Direction {
  Increasing
  Decreasing
} derive(Debug)

///|
pub(all) struct Sample {
  x : Double
  y : Double
  weight : Double
} derive(Debug)

///|
pub(all) struct Block {
  start : Int
  end : Int
  weight : Double
  value : Double
} derive(Debug)

///|
pub(all) struct Fit {
  values : Array[Double]
  blocks : Array[Block]
  objective : Double
  direction : Direction
} derive(Debug)

///|
pub fn sample(x : Double, y : Double, weight? : Double = 1.0) -> Sample {
  { x, y, weight, }
}

///|
fn finite(x : Double) -> Bool {
  x == x && x.abs() <= 1.7976931348623157e308
}

///|
fn validate_series(
  y : Array[Double],
  weights : Array[Double],
) -> Result[Unit, String] {
  if y.length() == 0 {
    return Err("empty observations")
  }
  if y.length() != weights.length() {
    return Err("weight length mismatch")
  }
  let mut total = 0.0
  for i = 0; i < y.length(); i = i + 1 {
    if !finite(y[i]) {
      return Err("nonfinite observation")
    }
    if !finite(weights[i]) || weights[i] <= 0.0 {
      return Err("weights must be positive and finite")
    }
    total = total + weights[i]
    if !finite(total) {
      return Err("weight sum overflow")
    }
  }
  Ok(())
}

///|
pub fn validate_samples(samples : Array[Sample]) -> Result[Unit, String] {
  let y = []
  let weights = []
  for s in samples {
    if !finite(s.x) {
      return Err("nonfinite coordinate")
    }
    y.push(s.y)
    weights.push(s.weight)
  }
  validate_series(y, weights)
}

///|
fn before(a : Double, b : Double, direction : Direction) -> Bool {
  match direction {
    Increasing => a <= b
    Decreasing => a >= b
  }
}

///|
fn squared_loss(
  y : Array[Double],
  values : Array[Double],
  weights : Array[Double],
) -> Result[Double, String] {
  let mut loss = 0.0
  for i = 0; i < y.length(); i = i + 1 {
    let residual = values[i] - y[i]
    loss = loss + weights[i] * residual * residual
    if !finite(loss) {
      return Err("objective overflow")
    }
  }
  Ok(loss)
}

///|
#deprecated
pub extend Direction with @debug.Debug::{to_repr}

///|
#deprecated
pub extend Sample with @debug.Debug::{to_repr}

///|
#deprecated
pub extend Block with @debug.Debug::{to_repr}

///|
#deprecated
pub extend Fit with @debug.Debug::{to_repr}
