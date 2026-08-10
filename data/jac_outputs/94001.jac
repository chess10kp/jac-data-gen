"""
		Discretize a yaw angle into the 4 canonical yaw angles/directions
	"""
def discretize_yaw(yaw: float) -> int {
    yaw_normalized = 360 + yaw if yaw < 0 else yaw;
    if (yaw_normalized >= 315 and yaw_normalized <= 360) or (yaw_normalized >= 0 and yaw_normalized < 45) {
        return 0;
    } elif yaw_normalized >= 45 and yaw_normalized < 135 {
        return 90;
    } elif yaw_normalized >= 135 and yaw_normalized < 225 {
        return 180;
    } else {
        return -90;
    }
}