"""Gets a point on a parabola y = a x^2 + b x + c.

  The Parabola is determined by three points (0, start), (0.5, mid), (1, end) in
  the plane.

  Args:
    phase: Normalized to [0, 1]. A point on the x-axis of the parabola.
    start: The y value at x == 0.
    mid: The y value at x == 0.5.
    end: The y value at x == 1.

  Returns:
    The y value at x == phase.
  """
def _gen_parabola(phase: float, start: float, mid: float, end: float) -> float {
    mid_phase = 0.5;
    delta_1 = mid - start;
    delta_2 = end - start;
    delta_3 = mid_phase ** 2 - mid_phase;
    coef_a = (delta_1 - delta_2 * mid_phase) / delta_3;
    coef_b = (delta_2 * mid_phase ** 2 - delta_1) / delta_3;
    coef_c = start;
    return coef_a * phase ** 2 + coef_b * phase + coef_c;
}