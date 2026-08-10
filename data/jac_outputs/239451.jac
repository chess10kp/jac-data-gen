""" Ball region is the region of the ball according to robot.
      We assumed the robot as origin of coordinate system.

  Returns:
      int: 1 = top-right, 2 = top-left, 3 = bottom-left, 4 = bottom-right
  """
def calculateBallRegion(ballCoordinate: list[float], robotCoordinate: list[float]) -> int {
    ballRegion = 0;
    if ballCoordinate[0] > robotCoordinate[0] {
        if ballCoordinate[1] > robotCoordinate[1] {
            ballRegion = 1;
        } else {
            ballRegion = 4;
        }
    } elif ballCoordinate[1] > robotCoordinate[1] {
        ballRegion = 2;
    } else {
        ballRegion = 3;
    }
    return ballRegion;
}