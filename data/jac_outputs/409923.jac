"""
    Initializes board with 0s.

    Parameters:
       dimensions (tuple): dimensions of the board

    Returns: an nD board

    """
def initialize_tensor_board(dimensions: tuple[int, ...], value: int) -> list[int] {
    if len(dimensions) == 1 {
        return [value for _ in range(dimensions[0])];
    }
    return [
        initialize_tensor_board(dimensions[1:], value) for _ in range(dimensions[0])
    ] as list[int];
}