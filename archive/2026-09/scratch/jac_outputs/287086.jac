"""Return the area of a square with side length R."""
def area_square(r: Any) -> object {
    assert (r > 0) , 'A length must be positive';
    return (r * r);
}