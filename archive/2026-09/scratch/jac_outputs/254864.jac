"""Return the string representation of t. t must be in *seconds*"""
def format_time(t: float) -> object {
    if (t >= 60) {
        return f"{round((t / 60.0), 2)} mins";
    } else {
        return f"{round(t, 2)} secs";
    }
}