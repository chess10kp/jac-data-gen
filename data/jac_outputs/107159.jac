"""Convert obj to a graph element if possible, otherwise return None."""
def _as_graph_element(`obj: object) -> object | None {
    conv_fn = getattr(`obj, "_as_graph_element", None);
    if conv_fn and callable(conv_fn) {
        return conv_fn();
    }
    return None;
}