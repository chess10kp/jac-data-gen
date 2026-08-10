"""Returns 0, 90, 180 or 270 degrees counter clockwise."""
def directions(startxy: tuple[int, int], endxy: tuple[int, int]) -> int {
    start_x = startxy[0];
    start_y = startxy[1];
    end_x = endxy[0];
    end_y = endxy[1];
    if start_x < end_x {
        return 270;
    } elif start_x > end_x {
        return 90;
    } elif start_y < end_y {
        return 180;
    } else {
        return 0;
    }
}