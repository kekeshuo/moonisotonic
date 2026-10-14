///|
pub(all) struct Evaluation {
  count : Int
  weight : Double
  mse : Double
  mae : Double
  bias : Double
  maximum_error : Double
  loss : Double
} derive(Debug)

///|
pub fn evaluate_predictions(
  y : Array[Double],
  predictions : Array[Double],
  weights : Array[Double],
  loss? : Loss = Squared,
) -> Result[Evaluation, String] {
  match validate_series(y, weights) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  if predictions.length() != y.length() {
    return Err("prediction length mismatch")
  }
  let mut total_weight = 0.0
  let mut squared = 0.0
  let mut absolute = 0.0
  let mut bias = 0.0
  let mut maximum_error = 0.0
  for i = 0; i < y.length(); i = i + 1 {
    if !finite(predictions[i]) {
      return Err("nonfinite prediction")
    }
    let error = predictions[i] - y[i]
    if !finite(error) {
      return Err("error overflow")
    }
    total_weight = total_weight + weights[i]
    squared = squared + weights[i] * error * error
    absolute = absolute + weights[i] * error.abs()
    bias = bias + weights[i] * error
    if error.abs() > maximum_error {
      maximum_error = error.abs()
    }
    if !finite(squared) || !finite(absolute) || !finite(bias) {
      return Err("evaluation overflow")
    }
  }
  let objective = match loss {
    Squared => squared
    Absolute => absolute
    Quantile(tau) =>
      match pinball_loss(y, predictions, weights, tau) {
        Err(e) => return Err(e)
        Ok(v) => v
      }
  }
  Ok({
    count: y.length(),
    weight: total_weight,
    mse: squared / total_weight,
    mae: absolute / total_weight,
    bias: bias / total_weight,
    maximum_error,
    loss: objective / total_weight,
  })
}

///|
pub fn evaluate(
  model : Model,
  samples : Array[Sample],
) -> Result[Evaluation, String] {
  match validate_samples(samples) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  let predictions = match predict_many(model, samples.map(fn(s) { s.x })) {
    Err(e) => return Err(e)
    Ok(v) => v
  }
  evaluate_predictions(
    samples.map(fn(s) { s.y }),
    predictions,
    samples.map(fn(s) { s.weight }),
    loss=model.loss,
  )
}

///|
pub fn evaluation_lines(evaluation : Evaluation) -> Array[String] {
  [
    "count=" + evaluation.count.to_string(),
    "weight=" + evaluation.weight.to_string(),
    "mse=" + evaluation.mse.to_string(),
    "mae=" + evaluation.mae.to_string(),
    "bias=" + evaluation.bias.to_string(),
    "maximum_error=" + evaluation.maximum_error.to_string(),
    "loss=" + evaluation.loss.to_string(),
  ]
}

///|
#deprecated
pub extend Evaluation with @debug.Debug::{to_repr}
