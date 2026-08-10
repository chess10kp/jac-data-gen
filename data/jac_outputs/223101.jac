"""Retrieve the absolute number corresponding a color set by color_dict."""
def get_color(color_dict: dict[str, int], colors: list[list[dict[str, int]]]) -> int {
    for (i, color) in enumerate(colors) {
        for data in color {
            equal = True;
            for (k, v) in data.items() {
                if k not in color_dict or v != color_dict[k] {
                    equal = False;
                    break;
                }
            }
            if equal {
                return i;
            }
        }
    }
    return -1;
}