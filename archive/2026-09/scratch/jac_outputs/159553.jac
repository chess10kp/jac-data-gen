"""Fill with zeros, if coord is missing seconds."""
def fill_zeros(coords: list[str]) -> list[str] {
    if len(coords) == 2 {
        if "." in coords[1] {
            coords = [coords[0], "00", coords[1]];
        } else {
            coords = [coords[0], coords[1], "00"];
        }
    }
    return coords;
}