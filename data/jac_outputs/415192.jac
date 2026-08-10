"""

Update bathrooms slider to sensible values.

"""
def update_bathrooms_slider(area: float) -> list[int] {
    return [1, min(int(area / 40) + 1, 5)];
}