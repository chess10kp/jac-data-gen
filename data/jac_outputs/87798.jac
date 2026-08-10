"""Convert a 'glob' pattern for file name matching to a regular
expression. E.g. "foo.? bar*" -> "foo\.. \bar.*" """
def glob_to_regex(pattern: str) -> str {
    return "^" + pattern.replace(".", "\\.").replace("*", ".*").replace("?", ".") + "$";
}