"""Extract method/function name from its full name."""
def trim_method_name(full_name: str) -> str {
    point_pos = full_name.rfind('.');
    if point_pos != -1 {
        return full_name[point_pos + 1:];
    }
    return full_name;
}