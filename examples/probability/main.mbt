///|
fn main {
  let rows = [
    @iso.sample(0.1, 0.0),
    @iso.sample(0.4, 1.0),
    @iso.sample(0.6, 0.0),
    @iso.sample(0.9, 1.0),
    @iso.sample(0.2, 0.0),
    @iso.sample(0.8, 1.0),
  ]
  let result = @iso.holdout(rows, [0, 1, 2, 3], [4, 5]).unwrap()
  let comparison = @iso.compare_calibration(rows, result, bin_count=5).unwrap()
  guard result.predictions.length() == 2 else { panic() }
  guard result.predictions[0] <= result.predictions[1] else { panic() }
  guard comparison.before.brier >= 0.0 && comparison.after.brier >= 0.0 else {
    panic()
  }
  let portable = @iso.decode_model(@iso.encode_model(result.model).unwrap()).unwrap()
  guard @iso.predict_many(portable, [0.2, 0.8]).unwrap() == result.predictions else {
    panic()
  }
  println(
    "probability: disjoint holdout, reliability and JSON assertions passed",
  )
}
