"""Return a string with single and double quotes escaped, keyvalues style."""
def encode_quotes(string: str) -> str {
    return string.replace('"', '\\"').replace("'", "\\'");
}