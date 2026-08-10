"""Turns snake_case name into SnakeCase."""
def camelize(name: str) -> str {
    "".join([bit.capitalize() for bit in name.split("_")])
}