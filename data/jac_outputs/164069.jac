"""Flavor id of the flavor to test."""
def flavor_id(request: object) -> str | None {
    if hasattr(request, "param") {
        return getattr(request, "param") as str;
    }
    return None;
}