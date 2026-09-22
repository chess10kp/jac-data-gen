"""
Given a bunch of participants' open-interests and fees,
calculate the total current market score.
"""
def cur_mkt_score_a(a: float, ds: list[float], fs: list[float]) -> float {
  total = 0.0;
  for (d, f) in zip(ds, fs) {
    total += d ** (1 - a) * f ** a;
  }
  return total;
}