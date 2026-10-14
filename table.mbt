///|
fn parse_cell(text : StringView) -> Result[Double, String] {
  let value = @json.parse(text.trim()) catch {
    _ => return Err("invalid numeric cell")
  }
  json_number(value)
}

///|
/// Numeric TSV, not general CSV. Exact x/y/weight header; no quoting or missing values.
pub fn read_samples(
  text : String,
  max_rows? : Int = 100000,
) -> Result[Array[Sample], String] {
  if max_rows <= 0 || text.length() > 16000000 {
    return Err("table budget exceeded")
  }
  let lines = text.split("\n").to_array()
  if lines.length() == 0 || lines[0].trim() != "x\ty\tweight" {
    return Err("expected x/y/weight TSV header")
  }
  let samples = []
  for i = 1; i < lines.length(); i = i + 1 {
    let line = lines[i].trim()
    if line.length() == 0 {
      if i == lines.length() - 1 {
        continue
      }
      return Err("empty table row")
    }
    if samples.length() >= max_rows {
      return Err("row budget exceeded")
    }
    let cells = line.split("\t").to_array()
    if cells.length() != 3 {
      return Err("expected three numeric cells")
    }
    let x = match parse_cell(cells[0]) {
      Err(e) => return Err(e)
      Ok(v) => v
    }
    let y = match parse_cell(cells[1]) {
      Err(e) => return Err(e)
      Ok(v) => v
    }
    let weight = match parse_cell(cells[2]) {
      Err(e) => return Err(e)
      Ok(v) => v
    }
    samples.push(sample(x, y, weight~))
  }
  match validate_samples(samples) {
    Err(e) => Err(e)
    Ok(_) => Ok(samples)
  }
}

///|
pub fn write_samples(samples : Array[Sample]) -> Result[String, String] {
  match validate_samples(samples) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  let lines = ["x\ty\tweight"]
  for s in samples {
    lines.push(
      s.x.to_string() + "\t" + s.y.to_string() + "\t" + s.weight.to_string(),
    )
  }
  Ok(lines.join("\n") + "\n")
}

///|
pub fn write_predictions(
  samples : Array[Sample],
  model : Model,
) -> Result[String, String] {
  match validate_samples(samples) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  let predictions = match predict_many(model, samples.map(fn(s) { s.x })) {
    Err(e) => return Err(e)
    Ok(v) => v
  }
  let lines = ["x\ty\tweight\tprediction\tresidual"]
  for i = 0; i < samples.length(); i = i + 1 {
    let s = samples[i]
    let residual = s.y - predictions[i]
    if !finite(residual) {
      return Err("residual overflow")
    }
    lines.push(
      s.x.to_string() +
      "\t" +
      s.y.to_string() +
      "\t" +
      s.weight.to_string() +
      "\t" +
      predictions[i].to_string() +
      "\t" +
      residual.to_string(),
    )
  }
  Ok(lines.join("\n") + "\n")
}
