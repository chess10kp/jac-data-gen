"""Extract marker id from request's dictionary (defaults to None)."""
def _get_marker_param(params: dict[str, object]) -> object | None {
    return params.pop('marker', None);
}