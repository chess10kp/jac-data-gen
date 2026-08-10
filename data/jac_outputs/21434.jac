"""
    Colors elements in a dateframe
    green if positive and red if
    negative. Does not color NaN
    values.
    """
def color_negative_red(value: int | float) -> str {
    if value < 0 {
        color = "red";
    } elif value > 0 {
        color = "green";
    } else {
        color = "black";
    }
    return "color: %s" % color;
}