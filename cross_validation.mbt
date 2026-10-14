///|
pub(all) struct CrossValidation {
  predictions : Array[Double]
  aggregate : Evaluation
  folds : Array[Evaluation]
} derive(Debug)

///|
/// No shuffle, hidden random state or fold selection. Every row is validated once.
pub fn cross_validate(
  samples : Array[Sample],
  assignments : Array[Int],
  fold_count : Int,
  loss? : Loss = Squared,
  direction? : Direction = Increasing,
) -> Result[CrossValidation, String] {
  match validate_samples(samples) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  if assignments.length() != samples.length() {
    return Err("fold assignment length mismatch")
  }
  if fold_count < 2 || fold_count > samples.length() || fold_count > 1000 {
    return Err("invalid fold count")
  }
  let counts = Array::make(fold_count, 0)
  for f in assignments {
    if f < 0 || f >= fold_count {
      return Err("fold index outside range")
    }
    counts[f] = counts[f] + 1
  }
  for count in counts {
    if count == 0 {
      return Err("empty validation fold")
    }
  }
  let predictions = Array::make(samples.length(), 0.0)
  let folds = []
  for f = 0; f < fold_count; f = f + 1 {
    let training_indices = []
    let validation_indices = []
    for i = 0; i < samples.length(); i = i + 1 {
      if assignments[i] == f {
        validation_indices.push(i)
      } else {
        training_indices.push(i)
      }
    }
    let result = match
      holdout(samples, training_indices, validation_indices, loss~, direction~) {
      Err(e) => return Err(e)
      Ok(v) => v
    }
    folds.push(result.validation)
    for j = 0; j < validation_indices.length(); j = j + 1 {
      predictions[validation_indices[j]] = result.predictions[j]
    }
  }
  let aggregate = match
    evaluate_predictions(
      samples.map(fn(s) { s.y }),
      predictions,
      samples.map(fn(s) { s.weight }),
      loss~,
    ) {
    Err(e) => return Err(e)
    Ok(v) => v
  }
  Ok({ predictions, aggregate, folds, })
}

///|
/// Caller-controlled chronological block folds, useful when random mixing is undesirable.
pub fn contiguous_folds(
  size : Int,
  fold_count : Int,
) -> Result[Array[Int], String] {
  if size <= 0 || fold_count < 2 || fold_count > size || size > 1000000 {
    return Err("invalid fold dimensions")
  }
  let base = size / fold_count
  let extra = size % fold_count
  let assignments = []
  for f = 0; f < fold_count; f = f + 1 {
    let count = base + (if f < extra { 1 } else { 0 })
    for _i = 0; _i < count; _i = _i + 1 {
      assignments.push(f)
    }
  }
  Ok(assignments)
}

///|
#deprecated
pub extend CrossValidation with @debug.Debug::{to_repr}
