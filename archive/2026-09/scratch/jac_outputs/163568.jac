"""Transforms an array of ports into a dictionary, referenced by port number."""
def invert(port_array: list[dict[str, int]], placeholder: list[dict[str, int]]) -> list[dict[str, int]] | dict[int, dict[str, int]] {
    if port_array == placeholder {
        return port_array;
    }
    prev: dict[int, dict[str, int]] = {};
    for p in port_array {
        prev[p['port_no']] = p;
    }
    return prev;
}