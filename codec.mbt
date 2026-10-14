///|
/// Versioned data schema: [schema, direction, loss, quantile, [[x,y,weight],...]].
pub fn encode_model(model : Model) -> Result[String, String] {
  match validate_model(model) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  let direction = match model.direction {
    Increasing => "increasing"
    Decreasing => "decreasing"
  }
  let (loss, tau) = match model.loss {
    Squared => ("squared", 0.0)
    Absolute => ("absolute", 0.0)
    Quantile(tau) => ("quantile", tau)
  }
  let knots = model.knots.map(fn(k) {
    Json::array([Json::number(k.x), Json::number(k.y), Json::number(k.weight)])
  })
  Ok(
    Json::array([
      Json::string("moonisotonic/1"),
      Json::string(direction),
      Json::string(loss),
      Json::number(tau),
      Json::array(knots),
    ]).stringify(),
  )
}

///|
fn json_number(value : Json) -> Result[Double, String] {
  match value {
    Number(number, ..) =>
      if finite(number) {
        Ok(number)
      } else {
        Err("nonfinite JSON number")
      }
    _ => Err("expected JSON number")
  }
}

///|
/// Parse bounded, untrusted model data. No executable code or callbacks in the format.
pub fn decode_model(
  text : String,
  max_knots? : Int = 100000,
) -> Result[Model, String] {
  if max_knots <= 0 {
    return Err("nonpositive knot limit")
  }
  if text.length() > 16000000 {
    return Err("model text exceeds 16 million UTF-16 units")
  }
  let value = @json.parse(text) catch { _ => return Err("invalid model JSON") }
  let fields = match value {
    Array(fields) => fields
    _ => return Err("expected model array")
  }
  if fields.length() != 5 {
    return Err("model field count mismatch")
  }
  match fields[0] {
    String("moonisotonic/1") => ()
    _ => return Err("unsupported schema version")
  }
  let direction = match fields[1] {
    String("increasing") => Increasing
    String("decreasing") => Decreasing
    _ => return Err("invalid model direction")
  }
  let tau = match json_number(fields[3]) {
    Err(e) => return Err(e)
    Ok(v) => v
  }
  let loss = match fields[2] {
    String("squared") =>
      if tau == 0.0 {
        Squared
      } else {
        return Err("unexpected squared quantile")
      }
    String("absolute") =>
      if tau == 0.0 {
        Absolute
      } else {
        return Err("unexpected absolute quantile")
      }
    String("quantile") => Quantile(tau)
    _ => return Err("invalid loss name")
  }
  let rows = match fields[4] {
    Array(rows) => rows
    _ => return Err("expected knot array")
  }
  if rows.length() > max_knots {
    return Err("knot budget exceeded")
  }
  let knots : Array[Knot] = []
  for row in rows {
    let values = match row {
      Array(values) => values
      _ => return Err("expected knot row")
    }
    if values.length() != 3 {
      return Err("knot field count mismatch")
    }
    let x = match json_number(values[0]) {
      Err(e) => return Err(e)
      Ok(v) => v
    }
    let y = match json_number(values[1]) {
      Err(e) => return Err(e)
      Ok(v) => v
    }
    let weight = match json_number(values[2]) {
      Err(e) => return Err(e)
      Ok(v) => v
    }
    knots.push({ x, y, weight, })
  }
  let model = { knots, direction, loss, }
  match validate_model(model) {
    Err(e) => Err(e)
    Ok(_) => Ok(model)
  }
}
