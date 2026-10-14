///|
pub(all) struct ReliabilityBin {
  index : Int
  count : Int
  weight : Double
  mean_prediction : Double
  event_rate : Double
  gap : Double
} derive(Debug)

///|
pub(all) struct Reliability {
  bins : Array[ReliabilityBin]
  brier : Double
  ece : Double
  maximum_gap : Double
} derive(Debug)

///|
fn check_probability_data(
  labels : Array[Double],
  predictions : Array[Double],
  weights : Array[Double],
) -> Result[Unit, String] {
  match validate_series(labels, weights) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  if labels.length() != predictions.length() {
    return Err("probability length mismatch")
  }
  for i = 0; i < labels.length(); i = i + 1 {
    if labels[i] < 0.0 || labels[i] > 1.0 {
      return Err("event rates outside [0,1]")
    }
    if !finite(predictions[i]) || predictions[i] < 0.0 || predictions[i] > 1.0 {
      return Err("probabilities outside [0,1]")
    }
  }
  Ok(())
}

///|
/// Fixed-width bins; exactly 1 belongs to the final bin. Empty bins are omitted.
pub fn reliability(
  labels : Array[Double],
  predictions : Array[Double],
  weights : Array[Double],
  bin_count? : Int = 10,
) -> Result[Reliability, String] {
  match check_probability_data(labels, predictions, weights) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  if bin_count <= 0 || bin_count > 10000 {
    return Err("bin count outside [1,10000]")
  }
  let counts = Array::make(bin_count, 0)
  let sums = Array::make(bin_count, 0.0)
  let events = Array::make(bin_count, 0.0)
  let totals = Array::make(bin_count, 0.0)
  let mut total_weight = 0.0
  for i = 0; i < labels.length(); i = i + 1 {
    let raw = (predictions[i] * bin_count.to_double()).to_int()
    let b = if raw >= bin_count { bin_count - 1 } else { raw }
    counts[b] = counts[b] + 1
    sums[b] = sums[b] + weights[i] * predictions[i]
    events[b] = events[b] + weights[i] * labels[i]
    totals[b] = totals[b] + weights[i]
    total_weight = total_weight + weights[i]
  }
  let bins : Array[ReliabilityBin] = []
  let mut ece = 0.0
  let mut maximum_gap = 0.0
  for i = 0; i < bin_count; i = i + 1 {
    if counts[i] == 0 {
      continue
    }
    let mean_prediction = sums[i] / totals[i]
    let event_rate = events[i] / totals[i]
    let gap = (mean_prediction - event_rate).abs()
    ece = ece + totals[i] / total_weight * gap
    if gap > maximum_gap {
      maximum_gap = gap
    }
    bins.push({
      index: i,
      count: counts[i],
      weight: totals[i],
      mean_prediction,
      event_rate,
      gap,
    })
  }
  let e = match evaluate_predictions(labels, predictions, weights) {
    Err(e) => return Err(e)
    Ok(v) => v
  }
  Ok({ bins, brier: e.mse, ece, maximum_gap, })
}

///|
pub fn train_probability(
  samples : Array[Sample],
  direction? : Direction = Increasing,
) -> Result[Model, String] {
  match validate_samples(samples) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  for s in samples {
    if s.y < 0.0 || s.y > 1.0 {
      return Err("event rates outside [0,1]")
    }
  }
  train_l2(samples, direction~)
}

///|
#deprecated
pub extend ReliabilityBin with @debug.Debug::{to_repr}

///|
#deprecated
pub extend Reliability with @debug.Debug::{to_repr}
