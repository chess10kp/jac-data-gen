"""Add the first group to get report with some factor"""
def _guess_header(info: Any) -> object {
    value = "group";
    if ("metadata" in info) {
        if info["metadata"] {
            return ",".join(map(str, info["metadata"].keys()));
        }
    }
    return value;
}