"""Return a colour reference from a pylint score"""
def get_color(score: float) -> str {
    colors = {
        "brightgreen": "#4c1",
        "green": "#97CA00",
        "yellow": "#dfb317",
        "yellowgreen": "#a4a61d",
        "orange": "#fe7d37",
        "red": "#e05d44",
        "bloodred": "#ff0000",
        "blue": "#007ec6",
        "grey": "#555",
        "gray": "#555",
        "lightgrey": "#9f9f9f",
        "lightgray": "#9f9f9f"
    };
    if score > 9 {
        return colors["brightgreen"];
    }
    if score > 8 {
        return colors["green"];
    }
    if score > 7.5 {
        return colors["yellowgreen"];
    }
    if score > 6.6 {
        return colors["yellow"];
    }
    if score > 5.0 {
        return colors["orange"];
    }
    if score > 0.0 {
        return colors["red"];
    }
    return colors["bloodred"];
}