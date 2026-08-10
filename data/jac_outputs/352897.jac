"""Detects bool type from string."""
def str2bool(bool_string: str) -> bool | None {
    if not bool_string {
        return None;
    }
    return bool_string.lower() in ("yes", "true", "1");
}