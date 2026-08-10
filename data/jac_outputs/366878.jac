"""Convert words into CamelCase."""
def camel_case(name: str) -> str {
    ''.join(name.capitalize().split())
}