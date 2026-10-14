///|
fn oracle_l2(
  y : Array[Double],
  w : Array[Double],
  direction : Direction,
) -> Double {
  let n = y.length()
  let mut optimum = 1.0e100
  for mask = 0; mask < 1 << (n - 1); mask = mask + 1 {
    let candidate = Array::make(n, 0.0)
    let mut start = 0
    for end = 1; end <= n; end = end + 1 {
      if end == n || (mask & (1 << (end - 1))) != 0 {
        let mut sum = 0.0
        let mut weight = 0.0
        for j = start; j < end; j = j + 1 {
          sum = sum + y[j] * w[j]
          weight = weight + w[j]
        }
        for j = start; j < end; j = j + 1 {
          candidate[j] = sum / weight
        }
        start = end
      }
    }
    if audit_order(candidate, direction~).unwrap().violations.length() == 0 {
      let value = squared_loss(y, candidate, w).unwrap()
      if value < optimum {
        optimum = value
      }
    }
  }
  optimum
}

///|
fn oracle_quantile(
  y : Array[Double],
  w : Array[Double],
  tau : Double,
  direction : Direction,
  limit : Int,
) -> Double {
  let mut optimum = 1.0e100
  for code = 0; code < limit; code = code + 1 {
    let mut number = code
    let candidate = []
    for _i = 0; _i < y.length(); _i = _i + 1 {
      candidate.push((number % 3).to_double())
      number = number / 3
    }
    if audit_order(candidate, direction~).unwrap().violations.length() == 0 {
      let value = pinball_loss(y, candidate, w, tau).unwrap()
      if value < optimum {
        optimum = value
      }
    }
  }
  optimum
}

///|
test "exhaustive length-one-to-five PAVA optimality in both directions" {
  let mut limit = 1
  for n = 1; n <= 5; n = n + 1 {
    limit = limit * 3
    for code = 0; code < limit; code = code + 1 {
      let mut number = code
      let y = []
      let w = []
      for i = 0; i < n; i = i + 1 {
        y.push((number % 3).to_double())
        w.push((i % 2 + 1).to_double())
        number = number / 3
      }
      for direction in [Increasing, Decreasing] {
        let fitted = fit_l2(y, w, direction~).unwrap()
        assert_true(
          (fitted.objective - oracle_l2(y, w, direction)).abs() < 1.0e-9,
        )
        assert_true(
          audit_order(fitted.values, direction~).unwrap().violations.length() ==
          0,
        )
        let twice = fit_l2(fitted.values, w, direction~).unwrap()
        for i = 0; i < n; i = i + 1 {
          assert_true((twice.values[i] - fitted.values[i]).abs() < 1.0e-9)
        }
        for tau in [0.25, 0.5, 0.75] {
          let quantile = fit_quantile(y, w, tau, direction~).unwrap()
          assert_true(
            (quantile.objective - oracle_quantile(y, w, tau, direction, limit)).abs() <
            1.0e-9,
          )
        }
      }
    }
  }
}

///|
test "contracts reject arithmetic failure malformed partitions and bad model data" {
  let nan = 0.0 / 0.0
  let inf = 1.0 / 0.0
  assert_true(isotonic([nan]) is Err(_))
  assert_true(isotonic([inf]) is Err(_))
  assert_true(fit_l2([1.0], [inf]) is Err(_))
  assert_true(isotonic([1.0e200, -1.0e200]) is Err(_))
  assert_true(
    expand_blocks([{ start: 1, end: 2, weight: 1.0, value: 0.0, }], 2) is Err(_),
  )
  assert_true(
    decode_model(
      "[\"moonisotonic/1\",\"increasing\",\"squared\",0,[[1,2,1],[0,3,1]]]",
    )
    is Err(_),
  )
  assert_true(
    decode_model(
      "[\"moonisotonic/1\",\"increasing\",\"squared\",0,[[0,2,1],[1,1,1]]]",
    )
    is Err(_),
  )
}
