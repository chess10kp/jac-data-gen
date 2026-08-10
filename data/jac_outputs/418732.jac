"""Custom Parse Type to parse a boolean value.

The same values are parsed as YAML does:
    http://yaml.org/type/bool.html

Plus 0 and 1
"""
def boolean_type(text: str) -> bool {
    text = text.lower();
    return text == "1" or text.startswith("y") or text == "true" or text == "on";
}