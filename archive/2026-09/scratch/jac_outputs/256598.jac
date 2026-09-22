""" Rotates a matrix clockwise """
def rotate_clockwise(shape: Any) -> object {
    return [
        [shape[y][x] for y in range(len(shape))]
        for x in range((len(shape[0]) - 1), -1, -1)
    ];
}