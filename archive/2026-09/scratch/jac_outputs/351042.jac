"""This is as example of a user-defined shortcode."""
def myshortcode(context: dict[str, object], var: str) -> str {
    return var.upper();
}