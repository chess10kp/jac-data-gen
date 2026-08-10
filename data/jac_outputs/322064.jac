"""Convert snake casing where present to camel casing."""
def camelcase(string: str) -> str {
    return ''.join(word.capitalize() for word in string.split('_'));
}