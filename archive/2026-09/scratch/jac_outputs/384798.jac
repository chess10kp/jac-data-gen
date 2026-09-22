"""Get the top N lines of a ``scope`` list for an individual :model:`rolodex.ProjectScope`."""
def get_scope_preview(value: str, n: int) -> str {
    return "\n".join(value.split("\r\n")[0:n]);
}