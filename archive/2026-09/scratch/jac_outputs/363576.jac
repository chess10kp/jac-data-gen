"""Get whether auto-snake is in use or not."""
def _uses_auto_snake(super_class: type) -> bool {
    return getattr(super_class, "__deserialize_auto_snake__", False);
}