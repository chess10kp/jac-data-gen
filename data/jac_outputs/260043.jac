"""Convert color list to ipycytoscape css format."""
def get_color_list_css(color_list: list[tuple[int, int, int]]) -> list[str] {
    return [f"rgb({r},{g},{b})" for (r, g, b) in color_list];
}