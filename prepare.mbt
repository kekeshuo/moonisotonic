///|
pub(all) struct Prepared {
  samples : Array[Sample]
  original_indices : Array[Int]
  coordinates : Array[Double]
  offsets : Array[Int]
  means : Array[Double]
  weights : Array[Double]
} derive(Debug)

///|
/// Sort by x and then original row, preserving duplicates for nonquadratic fits.
pub fn prepare(samples : Array[Sample]) -> Result[Prepared, String] {
  match validate_samples(samples) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  let order : Array[(Sample, Int)] = []
  for i = 0; i < samples.length(); i = i + 1 {
    order.push((samples[i], i))
  }
  order.sort_by(fn(a, b) {
    let c = a.0.x.compare(b.0.x)
    if c == 0 {
      a.1.compare(b.1)
    } else {
      c
    }
  })
  let sorted = order.map(fn(pair) { pair.0 })
  let original_indices = order.map(fn(pair) { pair.1 })
  let coordinates = []
  let offsets = []
  let means = []
  let weights = []
  let mut start = 0
  while start < sorted.length() {
    let mut end = start + 1
    let mut weight = sorted[start].weight
    let mut mean = sorted[start].y
    while end < sorted.length() && sorted[end].x == sorted[start].x {
      let next_weight = weight + sorted[end].weight
      mean = mean * (weight / next_weight) +
        sorted[end].y * (sorted[end].weight / next_weight)
      weight = next_weight
      end = end + 1
    }
    if !finite(mean) {
      return Err("duplicate-group mean overflow")
    }
    coordinates.push(sorted[start].x)
    offsets.push(start)
    means.push(mean)
    weights.push(weight)
    start = end
  }
  offsets.push(sorted.length())
  Ok({
    samples: sorted,
    original_indices,
    coordinates,
    offsets,
    means,
    weights,
  })
}

///|
/// Restore a sorted vector to the caller's original sample order.
pub fn restore_order(
  values : Array[Double],
  permutation : Array[Int],
) -> Result[Array[Double], String] {
  if values.length() != permutation.length() {
    return Err("permutation length mismatch")
  }
  let result = Array::make(values.length(), 0.0)
  let seen = Array::make(values.length(), false)
  for i = 0; i < values.length(); i = i + 1 {
    let j = permutation[i]
    if j < 0 || j >= values.length() || seen[j] {
      return Err("invalid permutation")
    }
    if !finite(values[i]) {
      return Err("nonfinite value")
    }
    seen[j] = true
    result[j] = values[i]
  }
  Ok(result)
}

///|
pub fn group_replication_counts(
  prepared : Prepared,
) -> Result[Array[Int], String] {
  if prepared.offsets.length() != prepared.coordinates.length() + 1 {
    return Err("invalid group offsets")
  }
  let counts = []
  let mut next = 0
  for i = 0; i < prepared.coordinates.length(); i = i + 1 {
    if prepared.offsets[i] != next || prepared.offsets[i + 1] <= next {
      return Err("invalid group coverage")
    }
    counts.push(prepared.offsets[i + 1] - next)
    next = prepared.offsets[i + 1]
  }
  if next != prepared.samples.length() {
    return Err("incomplete group coverage")
  }
  Ok(counts)
}

///|
#deprecated
pub extend Prepared with @debug.Debug::{to_repr}
