"""Creates a valid PlantUML entity name from the given value."""
def make_entity_name(name: str) -> str {
    invalid_chars = "-=!#$%^&*[](){}/~'`<>:;";
    for char in invalid_chars {
        name = name.replace(char, "_");
    }
    return name;
}