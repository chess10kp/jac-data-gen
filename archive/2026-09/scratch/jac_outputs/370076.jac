"""Return the corresponding red cube path matched to a blue cube path."""
def red_cube_path(blue_path: str) -> str {
    start = blue_path.rfind('blue');
    return blue_path[:start] + 'red' + blue_path[start + 4:];
}