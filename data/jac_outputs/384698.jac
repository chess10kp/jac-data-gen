"""Convert snake_case to camelCase"""
def snake_to_camel(snake_string: str) -> str {
    components = snake_string.split('_');
    return components[0] + ''.join(x.title() for x in components[1:]);
}