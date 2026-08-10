"""Convert snake_case to Darwin_Case."""
def snake_to_darwin_case(text: str) -> str {
    return "_".join(map(str.capitalize, text.split("_")));
}