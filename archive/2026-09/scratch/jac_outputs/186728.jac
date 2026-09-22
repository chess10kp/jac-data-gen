"""
    Extracts 3 individual integers from a tuple and returns them.

    Parameter:
        x_color_tuple: a tuple of red, green and blue values for x
            coordinates

    Programs that use this function:
        - Vertical Striper 1 through 16, but get_x_color is called
          directly by the following functions.
            - stripe_vertically
            - stripe_vertically_alternate
            - stripe_vertically_alternate_2
            - stripe_vertically_reverse
            - stripe_vertically_reverse_alt
            - stripe_vertically_reverse_alt_2
    """
def get_x_color(x_color_tuple: Any) -> object {
    return (int(x_color_tuple[0]), int(x_color_tuple[1]), int(x_color_tuple[2]));
}