///|
fn main {
  let rows = @iso.read_samples(
    "x\ty\tweight\n0\t0\t1\n1\t4\t1\n2\t2\t1\n3\t6\t1\n",
  ).unwrap()
  let robust = @iso.train_l1(rows).unwrap()
  let table = @iso.write_predictions(rows, robust).unwrap()
  guard table.length() > 40 else { panic() }
  guard @iso.read_samples(@iso.write_samples(rows).unwrap()).unwrap().length() ==
    4 else {
    panic()
  }
  let band = @iso.train_band(rows, 0.25, 0.75).unwrap()
  let ranges = @iso.predict_band(band, [0.0, 1.5, 3.0]).unwrap()
  for r in ranges {
    guard r.lower <= r.upper else { panic() }
  }
  let fitted = @iso.fit_l1(
    rows.map(fn(s) { s.y }),
    rows.map(fn(s) { s.weight }),
  ).unwrap()
  let explanations = @iso.explain_fit(
    rows.map(fn(s) { s.y }),
    rows.map(fn(s) { s.weight }),
    fitted,
  ).unwrap()
  guard @iso.explanation_table(explanations).length() > 0 else { panic() }
  let cv = @iso.cross_validate(rows, [0, 1, 0, 1], 2, loss=Absolute).unwrap()
  guard cv.predictions.length() == 4 else { panic() }
  println(
    "analysis: TSV, L1, descriptive bands, block explanation and cross-validation passed",
  )
}
