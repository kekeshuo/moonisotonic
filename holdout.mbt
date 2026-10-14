///|
pub(all) struct Holdout {
  model : Model
  training : Evaluation
  validation : Evaluation
  predictions : Array[Double]
  validation_indices : Array[Int]
} derive(Debug)

///|
fn select_rows(
  samples : Array[Sample],
  indices : Array[Int],
  seen : Array[Bool],
) -> Result[Array[Sample], String] {
  if indices.length() == 0 {
    return Err("empty data partition")
  }
  let rows = []
  for i in indices {
    if i < 0 || i >= samples.length() || seen[i] {
      return Err("duplicate or overlapping partition index")
    }
    seen[i] = true
    rows.push(samples[i])
  }
  Ok(rows)
}

///|
/// Explicit row identity prevents accidentally training on validation rows.
pub fn holdout(
  samples : Array[Sample],
  training_indices : Array[Int],
  validation_indices : Array[Int],
  loss? : Loss = Squared,
  direction? : Direction = Increasing,
) -> Result[Holdout, String] {
  match validate_samples(samples) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  let seen = Array::make(samples.length(), false)
  let training_rows = match select_rows(samples, training_indices, seen) {
    Err(e) => return Err(e)
    Ok(v) => v
  }
  let validation_rows = match select_rows(samples, validation_indices, seen) {
    Err(e) => return Err(e)
    Ok(v) => v
  }
  let model = match train(training_rows, loss~, direction~) {
    Err(e) => return Err(e)
    Ok(v) => v
  }
  let training = match evaluate(model, training_rows) {
    Err(e) => return Err(e)
    Ok(v) => v
  }
  let validation = match evaluate(model, validation_rows) {
    Err(e) => return Err(e)
    Ok(v) => v
  }
  let predictions = match
    predict_many(model, validation_rows.map(fn(s) { s.x })) {
    Err(e) => return Err(e)
    Ok(v) => v
  }
  Ok({
    model,
    training,
    validation,
    predictions,
    validation_indices: validation_indices.copy(),
  })
}

///|
pub(all) struct CalibrationComparison {
  before : Reliability
  after : Reliability
  brier_change : Double
  ece_change : Double
} derive(Debug)

///|
/// Baseline score x must already be a probability. Negative change means improvement.
pub fn compare_calibration(
  samples : Array[Sample],
  result : Holdout,
  bin_count? : Int = 10,
) -> Result[CalibrationComparison, String] {
  let seen = Array::make(samples.length(), false)
  let rows = match select_rows(samples, result.validation_indices, seen) {
    Err(e) => return Err(e)
    Ok(v) => v
  }
  let labels = rows.map(fn(s) { s.y })
  let weights = rows.map(fn(s) { s.weight })
  let scores = rows.map(fn(s) { s.x })
  let before = match reliability(labels, scores, weights, bin_count~) {
    Err(e) => return Err(e)
    Ok(v) => v
  }
  let after = match
    reliability(labels, result.predictions, weights, bin_count~) {
    Err(e) => return Err(e)
    Ok(v) => v
  }
  Ok({
    before,
    after,
    brier_change: after.brier - before.brier,
    ece_change: after.ece - before.ece,
  })
}

///|
#deprecated
pub extend Holdout with @debug.Debug::{to_repr}

///|
#deprecated
pub extend CalibrationComparison with @debug.Debug::{to_repr}
