"""Adding indents in accordance with the level

    Args:
        col (int): level

    Returns:
        str:
    """
def print_ident(col: int) -> str {
    ident = '    ';
    out = '';
    for i in range(col) {
        out += ident;
    }
    return out;
}