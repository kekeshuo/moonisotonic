///|
pub(all) struct Sensitivity {
  queries : Array[Double]
  lower : Array[Double]
  median : Array[Double]
  upper : Array[Double]
  fits : Int
} derive(Debug)

///|
/// Explicit resampling plans only. No random-number generation or confidence-level claim.
pub fn resample_sensitivity(
  samples : Array[Sample],
  plans : Array[Array[Int]],
  queries : Array[Double],
  lower_tau? : Double = 0.1,
  upper_tau? : Double = 0.9,
  loss? : Loss = Squared,
  direction? : Direction = Increasing,
) -> Result[Sensitivity, String] {
  match validate_samples(samples) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  if plans.length() == 0 ||
    plans.length() > 200 ||
    queries.length() == 0 ||
    queries.length() > 10000 {
    return Err("sensitivity budget exceeded")
  }
  if !finite(lower_tau) ||
    !finite(upper_tau) ||
    lower_tau < 0.0 ||
    upper_tau > 1.0 ||
    lower_tau > 0.5 ||
    upper_tau < 0.5 {
    return Err("invalid sensitivity quantiles")
  }
  let predictions : Array[Array[Double]] = []
  let mut entries = 0
  for plan in plans {
    if plan.length() == 0 || plan.length() > 1000000 - entries {
      return Err("resample row budget exceeded")
    }
    entries = entries + plan.length()
    let rows = []
    for index in plan {
      if index < 0 || index >= samples.length() {
        return Err("resample index outside dataset")
      }
      rows.push(samples[index])
    }
    let model = match train(rows, loss~, direction~) {
      Err(e) => return Err(e)
      Ok(v) => v
    }
    let values = match predict_many(model, queries) {
      Err(e) => return Err(e)
      Ok(v) => v
    }
    predictions.push(values)
  }
  let lower = []
  let median = []
  let upper = []
  let weights = Array::make(plans.length(), 1.0)
  for i = 0; i < queries.length(); i = i + 1 {
    let values = predictions.map(fn(row) { row[i] })
    match weighted_quantile(values, weights, lower_tau) {
      Err(e) => return Err(e)
      Ok(v) => lower.push(v)
    }
    match weighted_quantile(values, weights, 0.5) {
      Err(e) => return Err(e)
      Ok(v) => median.push(v)
    }
    match weighted_quantile(values, weights, upper_tau) {
      Err(e) => return Err(e)
      Ok(v) => upper.push(v)
    }
  }
  Ok({ queries: queries.copy(), lower, median, upper, fits: plans.length(), })
}

///|
#deprecated
pub extend Sensitivity with @debug.Debug::{to_repr}
