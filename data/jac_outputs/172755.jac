"""Returns an indication where a particular module is templated."""
def is_templated(module: dict[str, str]) -> bool {
    if "attr" not in module {
        return False;
    }
    return module["attr"] in ("templated",);
}