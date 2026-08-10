"""Find area of a box when given the box corners in a tuple."""
def find_area(coords: tuple[int | float, int | float, int | float, int | float]) -> int | float {
    (coords[1] - coords[0]) * (coords[3] - coords[2])
}