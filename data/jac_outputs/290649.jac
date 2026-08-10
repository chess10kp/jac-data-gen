"""Generate binary coordinates."""
def get_binary_indexes(coordinates: Any) -> object {
    bin_coordinates = [];
    for coord in coordinates {
        coord = (
            "{:08b}".format(coord[0]),
            "{:08b}".format(coord[1]),
            "{:08b}".format(coord[2])
        );
        bin_coordinates.append(coord);
    }
    return bin_coordinates;
}