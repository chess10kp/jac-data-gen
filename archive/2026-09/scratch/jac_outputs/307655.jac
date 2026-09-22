"""Return the angle of the range index."""
def _get_angle(range_index: int, range_len: int, angle_increment: float) -> float {
    lidar_angle = (range_index - range_len / 2) * angle_increment;
    return lidar_angle / 2;
}