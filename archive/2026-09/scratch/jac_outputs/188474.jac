"""

    :param direction:
    :param position:
    :param boat_size:
    :param board_matrix:
    :return:
    """
def hits_boat(
    direction: Any, position: Any, boat_size: Any, board_matrix: Any
) -> object {
    if (direction == 'UP') {
        first_square = position['y'];
        for currentY in range(((first_square + 1) - boat_size), (first_square + 1)) {
            if (board_matrix[currentY][position['x']] != 0) {
                return True;
            }
        }
    } elif (direction == 'DOWN') {
        first_square = position['y'];
        for currentY in range(first_square, (first_square + boat_size)) {
            if (board_matrix[currentY][position['x']] != 0) {
                return True;
            }
        }
    } elif (direction == 'RIGHT') {
        first_square = position['x'];
        for currentX in range(first_square, (first_square + boat_size)) {
            if (board_matrix[position['y']][currentX] != 0) {
                return True;
            }
        }
    } elif (direction == 'LEFT') {
        first_square = position['x'];
        for currentX in range(((first_square + 1) - boat_size), (first_square + 1)) {
            if (board_matrix[position['y']][currentX] != 0) {
                return True;
            }
        }
    }
    return False;
}