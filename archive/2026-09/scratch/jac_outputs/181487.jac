"""Format the cell of a latex table."""
def cell(data: str, label: str, spec: dict[str, object]) -> str {
    add_math_mode = ("^" in data or "_" in data) and "$" not in data;
    return ("$" + data + "$") if add_math_mode else data;
}