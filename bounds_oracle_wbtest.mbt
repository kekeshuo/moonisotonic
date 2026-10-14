///|
fn independent_bounded_cost(
  y : Array[Double],
  w : Array[Double],
  lo : Array[Double],
  hi : Array[Double],
  direction : Direction,
) -> Double {
  let n = y.length()
  let mut best = 1.0e100
  for mask = 0; mask < 1 << (n - 1); mask = mask + 1 {
    let candidate = Array::make(n, 0.0)
    let mut start = 0
    let mut valid = true
    for end = 1; end <= n; end = end + 1 {
      if end == n || (mask & (1 << (end - 1))) != 0 {
        let mut lower = lo[start]
        let mut upper = hi[start]
        let mut sum = 0.0
        let mut weight = 0.0
        for j = start; j < end; j = j + 1 {
          if lo[j] > lower {
            lower = lo[j]
          }
          if hi[j] < upper {
            upper = hi[j]
          }
          sum = sum + y[j] * w[j]
          weight = weight + w[j]
        }
        if lower > upper {
          valid = false
        }
        let mean = sum / weight
        let value = if mean < lower {
          lower
        } else if mean > upper {
          upper
        } else {
          mean
        }
        for j = start; j < end; j = j + 1 {
          candidate[j] = value
        }
        start = end
      }
    }
    for j = 1; j < n; j = j + 1 {
      match direction {
        Increasing => if candidate[j - 1] > candidate[j] { valid = false }
        Decreasing => if candidate[j - 1] < candidate[j] { valid = false }
      }
    }
    if valid {
      let mut cost = 0.0
      for j = 0; j < n; j = j + 1 {
        cost = cost + w[j] * (y[j] - candidate[j]) * (y[j] - candidate[j])
      }
      if cost < best {
        best = cost
      }
    }
  }
  best
}

///|
test "1638 bounded oracle fits including infeasible interval chains" {
  let mut limit = 1
  for n = 1; n <= 3; n = n + 1 {
    limit = limit * 9
    for code = 0; code < limit; code = code + 1 {
      let mut value = code
      let y = []
      let lo = []
      let hi = []
      let w = []
      for i = 0; i < n; i = i + 1 {
        let digit = value % 9
        value = value / 9
        y.push((digit % 3).to_double())
        let interval = digit / 3
        lo.push(if interval == 1 { 1.0 } else { 0.0 })
        hi.push(if interval == 0 { 1.0 } else { 2.0 })
        w.push((i % 2 + 1).to_double())
      }
      for direction in [Increasing, Decreasing] {
        let optimum = independent_bounded_cost(y, w, lo, hi, direction)
        match fit_bounded(y, w, lo, hi, direction~) {
          Err(_) => assert_eq(optimum, 1.0e100)
          Ok(fit) => {
            assert_true((fit.objective - optimum).abs() < 1.0e-9)
            for i = 0; i < n; i = i + 1 {
              assert_true(fit.values[i] >= lo[i] && fit.values[i] <= hi[i])
            }
          }
        }
      }
    }
  }
}
