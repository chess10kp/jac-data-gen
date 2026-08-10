"""Replace escape characters in JSON pointer."""
def json_pointer(jsonpointer: str) -> str {
    jsonpointer.replace("~0", "~").replace("~1", "/")
}