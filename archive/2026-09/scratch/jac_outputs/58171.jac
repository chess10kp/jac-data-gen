"""mode escape sequence code for background or foreground color
    string string to be formatted
    color used color"""
def __color(mode: int, string: str, color: int | tuple[int, int, int] | str) -> str {
    if isinstance(color, int) {
        escape = "\x1b[{0}8:5:{1}m".format(mode, color);
    } elif isinstance(color, tuple) {
        (r, g, b) = color;
        escape = "\x1b[{0}8;2;{1};{2};{3}m".format(mode, r, g, b);
    } elif isinstance(color, str) {
        if not color.startswith('#') {
            try {
                color = int(color);
                return __color(mode, string, int(color));
            } except ValueError {
                return string;
            }
        }
        r = int(color[1:3], 16);
        g = int(color[3:5], 16);
        b = int(color[5:7], 16);
        escape = "\x1b[{0}8;2;{1};{2};{3}m".format(mode, r, g, b);
    } else {
        return string;
    }
    return escape + string.replace("\x1b[0m", '') + "\x1b[0m";
}