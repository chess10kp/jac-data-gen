"""Convert number to human readable string."""
def humanize_number(x: Any) -> object {
    abs_x = abs(x);
    if (abs_x > 1000000.0) {
        return f"{(x / 1000000.0):.0f}m";
    } elif (abs_x > 1000.0) {
        return f"{(x / 1000.0):.0f}k";
    } elif (abs_x > 10) {
        return f"{x:.0f}";
    } else {
        return f"{x:.3f}";
    }
}