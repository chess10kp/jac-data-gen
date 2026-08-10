"""Checks if the cli command contains any options (e.g. --regex $REGEX)."""
def has_options(cli: list[str]) -> bool {
    return any('--' in item for item in cli);
}