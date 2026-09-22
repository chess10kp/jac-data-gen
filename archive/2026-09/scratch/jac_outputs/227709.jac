"""Fix template expansion after hook copy."""
def fix_template_expansion(content: str, replacements: list[dict[str, str]]) -> str {
    for replacement in replacements {
        for (key, to_be_replaced) in replacement.items() {
            template = (
                chr(123) + chr(123) + "cookiecutter." + key + chr(125) + chr(125)
            );
            content = content.replace(to_be_replaced, template);
        }
    }
    return content;
}