"""Returns the area of a regular polygon"""
def regular_polygon_area(perimeter: int | float, apothem: int | float) -> float {
    return (perimeter * apothem) / 2;
}