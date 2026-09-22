"""Interpret 'color' as an HTML color."""
def html_color(color: str | list[float]) -> str | None {
    if isinstance(color, str) {
        lower = color.lower();
        if lower == "r" {
            return "#ff0000";
        } elif lower == "g" {
            return "#00ff00";
        } elif lower == "b" {
            return "#0000ff";
        } elif color.startswith("#") {
            return color;
        }
    } elif len(color) == 3 {
        return '#'
            + ''.join(
                [hex(int(float_color * 255))[2:].zfill(2) for float_color in color]
            );
    } else {
        raise Exception("Color not recognized: " + str(color));
    }
}