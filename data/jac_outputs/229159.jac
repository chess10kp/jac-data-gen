"""Return the options of an expansion.  If options are not defined, return {}"""
def exp_opts(expansion: str | tuple[str, dict[str, str]]) -> dict[str, str] {
    if isinstance(expansion, str) {
        return {};
    }
    return expansion[1];
}