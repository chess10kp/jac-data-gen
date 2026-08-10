"""Return method classification based on callable name, or None if not callable."""
def get_method_type(method: Callable) -> str | None {
    if not callable(method) {
        return None;
    } elif method.__name__[:9] == "_graph_fn" {
        return "graph_fn";
    }
    return "unknown";
}