"""Returns first package name. From `a.b.c` it returns `a`."""
def get_first_package_name(name: str) -> str {
    return name.split(".")[0];
}