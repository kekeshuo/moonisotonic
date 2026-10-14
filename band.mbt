///|
pub(all) struct QuantileBand {
  lower : Model
  upper : Model
  lower_tau : Double
  upper_tau : Double
} derive(Debug)

///|
pub fn train_band(
  samples : Array[Sample],
  lower_tau : Double,
  upper_tau : Double,
  direction? : Direction = Increasing,
) -> Result[QuantileBand, String] {
  if !finite(lower_tau) ||
    !finite(upper_tau) ||
    lower_tau <= 0.0 ||
    upper_tau >= 1.0 ||
    lower_tau >= upper_tau {
    return Err("invalid quantile envelope levels")
  }
  let lower = match train_quantile(samples, lower_tau, direction~) {
    Err(e) => return Err(e)
    Ok(v) => v
  }
  let upper = match train_quantile(samples, upper_tau, direction~) {
    Err(e) => return Err(e)
    Ok(v) => v
  }
  for i = 0; i < lower.knots.length(); i = i + 1 {
    if lower.knots[i].x != upper.knots[i].x ||
      lower.knots[i].y > upper.knots[i].y {
      return Err("crossing empirical quantiles")
    }
  }
  Ok({ lower, upper, lower_tau, upper_tau, })
}

///|
pub fn predict_band(
  band : QuantileBand,
  queries : Array[Double],
) -> Result[Array[InverseRange], String] {
  if band.lower_tau <= 0.0 ||
    band.upper_tau >= 1.0 ||
    band.lower_tau >= band.upper_tau {
    return Err("invalid band levels")
  }
  let lower = match predict_many(band.lower, queries) {
    Err(e) => return Err(e)
    Ok(v) => v
  }
  let upper = match predict_many(band.upper, queries) {
    Err(e) => return Err(e)
    Ok(v) => v
  }
  let ranges : Array[InverseRange] = []
  for i = 0; i < queries.length(); i = i + 1 {
    if lower[i] > upper[i] {
      return Err("crossing band at query")
    }
    ranges.push({ lower: lower[i], upper: upper[i], })
  }
  Ok(ranges)
}

///|
pub(all) struct BandCoverage {
  count : Int
  weight : Double
  covered_weight : Double
  coverage : Double
  mean_width : Double
} derive(Debug)

///|
/// Descriptive empirical coverage, not a confidence guarantee.
pub fn band_coverage(
  band : QuantileBand,
  samples : Array[Sample],
) -> Result[BandCoverage, String] {
  match validate_samples(samples) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  let ranges = match predict_band(band, samples.map(fn(s) { s.x })) {
    Err(e) => return Err(e)
    Ok(v) => v
  }
  let mut weight = 0.0
  let mut covered_weight = 0.0
  let mut width = 0.0
  for i = 0; i < samples.length(); i = i + 1 {
    let s = samples[i]
    let r = ranges[i]
    weight = weight + s.weight
    if s.y >= r.lower && s.y <= r.upper {
      covered_weight = covered_weight + s.weight
    }
    width = width + s.weight * (r.upper - r.lower)
  }
  if !finite(width) {
    return Err("band width overflow")
  }
  Ok({
    count: samples.length(),
    weight,
    covered_weight,
    coverage: covered_weight / weight,
    mean_width: width / weight,
  })
}

///|
#deprecated
pub extend QuantileBand with @debug.Debug::{to_repr}

///|
#deprecated
pub extend BandCoverage with @debug.Debug::{to_repr}
