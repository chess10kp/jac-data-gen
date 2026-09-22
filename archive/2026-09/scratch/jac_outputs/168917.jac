"""
    :param colors: a 1d list of length 20 floats in range [0, 1].
        return a 1d list of 5 html colors of the format "#RRGGBBAA".
    """
def rgba_to_htmlcolors(colors: Any) -> object {
    hexcolors = ["{:02x}".format(int((255 * x))).upper() for x in colors];
    return ["#{}{}{}{}".format(*hexcolors[(4 * i):((4 * i) + 4)]) for i in range(5)];
}