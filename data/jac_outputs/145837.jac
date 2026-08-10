"""Return msg_prefix with added value."""
def _msg_prefix_add(msg_prefix: str, value: str | int) -> str {
    msg_prefix = f"{msg_prefix}: " if msg_prefix else "";
    return f"{msg_prefix}{value}";
}