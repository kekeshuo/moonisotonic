///|
fn main {
  let rows = [
    @iso.sample(0.0, 10.0),
    @iso.sample(1.0, 6.0),
    @iso.sample(2.0, 8.0),
    @iso.sample(3.0, 2.0),
  ]
  let model = @iso.train_l2(rows, direction=Decreasing).unwrap()
  let plateau = @iso.inverse(model, 7.0).unwrap()
  guard plateau.lower == 1.0 && plateau.upper == 2.0 else { panic() }
  guard @iso.predict(model, 1.5).unwrap() == 7.0 else { panic() }
  let restored = @iso.decode_model(@iso.encode_model(model).unwrap()).unwrap()
  guard @iso.predict_many(restored, [0.0, 1.5, 3.0]).unwrap() ==
    [10.0, 7.0, 2.0] else {
    panic()
  }
  let below = @iso.threshold_domain(model, 7.0, above=false).unwrap()
  guard below.lower == 1.0 && below.upper == 3.0 else { panic() }
  println(
    "instrument: decreasing fit, plateau inverse and portable model assertions passed",
  )
}
