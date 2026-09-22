"""Use '-' as default instead of '_' for option as it is easier to type."""
def normalize_option_name(name: str) -> str {
    if name.startswith("--") {
        name = name.replace("_", "-");
    }
    return name;
}