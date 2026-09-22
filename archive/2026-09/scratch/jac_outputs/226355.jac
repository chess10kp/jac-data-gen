"""Replace non-word chars [-. ] with underscores [_]"""
def wordify(string: str) -> str {
    return string.replace("-", "_").replace(".", " ").replace(" ", "_");
}