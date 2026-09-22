"""Convert boolean value to 'enabled' or 'disabled'."""
def enabled_disabled(b: bool) -> str {
    return "enabled" if b else "disabled";
}