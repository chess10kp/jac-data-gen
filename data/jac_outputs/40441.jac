"""Examine color index from the name index value."""
def get_color_index(name_index: int, color_arr: list[int]) -> int {
    if name_index > len(color_arr) {
        return name_index % len(color_arr);
    }
    return name_index;
}