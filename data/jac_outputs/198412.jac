"""Get the leg swing zero point when the body is tilted.

  For example, when climbing up or down stairs/slopes, the robot body will tilt
  up or down. By compensating the body pitch, the leg's trajectory will be
  centered around the vertical direction (not perpendicular to the surface).
  This helps the robot to generate thrust when going upwards, and braking when
  going downwards.

  Args:
    body_pitch: Float. Current body pitch angle.
    desired_incline_angle: Float. The desired body pitch angle.

  Returns:
    The stance and swing leg swing offset.

  """
def get_leg_swing_offset_for_pitching(
    body_pitch: float, desired_incline_angle: float
) -> float {
    kp = 0.2;
    return -((1 - kp) * body_pitch + kp * desired_incline_angle);
}