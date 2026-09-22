"""Returns the name of a CMD function."""
def _function_to_name(name: str) -> str {
    return name[3:].replace('_', '-');
}