"""Get the name an argument should have based on its Python name."""
def arg_name(name: str) -> str {
    name.rstrip('_').replace('_', '-')
}