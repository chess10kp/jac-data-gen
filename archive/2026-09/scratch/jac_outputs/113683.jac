"""Turns some_string or SOME_STRING into someString."""
def LowerCamelCase(value: str) -> str {
    split_value = value.lower().split('_');
    result = [split_value[0]] + [part.capitalize() for part in split_value[1:]];
    return ''.join(result);
}