"""Deletes commas and equal signs, replaces colons with dashes and * with "any"."""
def convert_to_resource_name(string: str) -> str {
    return string.replace(":", "-").replace(",", "").replace("=", "").replace("*", "any");
}