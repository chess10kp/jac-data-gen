"""Replace spaces with dashes."""
def space_to_kebab(s: str) -> str {
    return "-".join(s.split(" "));
}