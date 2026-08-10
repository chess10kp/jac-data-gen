"""
    >>> get_next_coordinates(0, 0, '>')
    (1, 0)

    >>> get_next_coordinates(0, 0, '<')
    (-1, 0)

    >>> get_next_coordinates(0, 0, '^')
    (0, 1)

    >>> get_next_coordinates(0, 0, 'v')
    (0, -1)
    """
def get_next_coordinates(x: int, y: int, direction: str) -> tuple[int, int] {
    match direction {
        case '^':
            y += 1;
        case 'v':
            y -= 1;
        case '<':
            x -= 1;
        case '>':
            x += 1;
        case _:
            raise SyntaxError('Expected <^v> got {0}'.format(direction));
    }
    return (x, y);
}