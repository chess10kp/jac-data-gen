"""Compute yield as measured with UMIs for a droplet x."""
def compute_yield(x: dict[str, float | int]) -> float {
  return x["az_total"] * x["nb_hp"] * 10.0 / x["hp_total"];
}