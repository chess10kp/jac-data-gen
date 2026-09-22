"""convert snake_case to camelCase"""
def snake_to_camel(snake: str) -> str {
    components = snake.split("_");
    return components[0] + "".join([comp.title() for comp in components[1:]]);
}