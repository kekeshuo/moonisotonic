///|
pub(all) struct BlockExplanation {
  start : Int
  end : Int
  fitted : Double
  observed_mean : Double
  observed_min : Double
  observed_max : Double
  weight : Double
  squared_error : Double
  absolute_error : Double
} derive(Debug)

///|
pub fn explain_fit(
  y : Array[Double],
  weights : Array[Double],
  fit : Fit,
) -> Result[Array[BlockExplanation], String] {
  match validate_series(y, weights) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  let expanded = match expand_blocks(fit.blocks, y.length()) {
    Err(e) => return Err(e)
    Ok(v) => v
  }
  if expanded != fit.values {
    return Err("fit partition mismatch")
  }
  let explanations : Array[BlockExplanation] = []
  for block in fit.blocks {
    let mut weight = 0.0
    let mut observed_mean = 0.0
    let mut observed_min = y[block.start]
    let mut observed_max = y[block.start]
    let mut squared_error = 0.0
    let mut absolute_error = 0.0
    for i = block.start; i < block.end; i = i + 1 {
      let next_weight = weight + weights[i]
      observed_mean = observed_mean * (weight / next_weight) +
        y[i] * (weights[i] / next_weight)
      weight = next_weight
      if y[i] < observed_min {
        observed_min = y[i]
      }
      if y[i] > observed_max {
        observed_max = y[i]
      }
      let residual = block.value - y[i]
      squared_error = squared_error + weights[i] * residual * residual
      absolute_error = absolute_error + weights[i] * residual.abs()
    }
    if !finite(squared_error) ||
      !finite(absolute_error) ||
      !finite(observed_mean) {
      return Err("explanation arithmetic overflow")
    }
    if weight != block.weight {
      return Err("block weight mismatch")
    }
    explanations.push({
      start: block.start,
      end: block.end,
      fitted: block.value,
      observed_mean,
      observed_min,
      observed_max,
      weight,
      squared_error,
      absolute_error,
    })
  }
  Ok(explanations)
}

///|
pub fn explanation_table(explanations : Array[BlockExplanation]) -> String {
  let lines = [
    "start\tend\tfitted\tmean\tmin\tmax\tweight\tsquared_error\tabsolute_error",
  ]
  for e in explanations {
    lines.push(
      e.start.to_string() +
      "\t" +
      e.end.to_string() +
      "\t" +
      e.fitted.to_string() +
      "\t" +
      e.observed_mean.to_string() +
      "\t" +
      e.observed_min.to_string() +
      "\t" +
      e.observed_max.to_string() +
      "\t" +
      e.weight.to_string() +
      "\t" +
      e.squared_error.to_string() +
      "\t" +
      e.absolute_error.to_string(),
    )
  }
  lines.join("\n") + "\n"
}

///|
#deprecated
pub extend BlockExplanation with @debug.Debug::{to_repr}
