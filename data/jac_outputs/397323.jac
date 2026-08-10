""" translate tkinter hex color code #ffffff to rgb tuple of integers
        https://stackoverflow.com/a/29643643/6929343
    """
def hex_to_rgb(hex_str: str) -> tuple[int, int, int] {
    h = hex_str.lstrip('#');
    return tuple(int(h[i:(i + 2)], 16) for i in (0, 2, 4));
}