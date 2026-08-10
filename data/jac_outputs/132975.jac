"""Deserialize comma-separated dimension key=value pairs."""
def unserialize_dimensions(dims: str) -> dict[str, str] {
    if not dims {
        return {};
    }
    return dict(kv.split('=', 1) for kv in dims.split(','));
}