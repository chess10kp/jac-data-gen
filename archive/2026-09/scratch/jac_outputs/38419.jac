"""Helper function, returns \"yes\" if *b* is True, \"no\" if *b* is False."""
def bool2yn(b: bool) -> str {
    ["no", "yes"][b]
}