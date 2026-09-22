"""Convert camelCase variable names to snake_case."""
def change_variable_name(text: str) -> str {
    chars = [];
    for (index, char) in enumerate(text) {
        if char.isupper() and index != 0 {
            chars.append("_");
        }
        chars.append(char);
    }
    return "".join(chars).lower();
}