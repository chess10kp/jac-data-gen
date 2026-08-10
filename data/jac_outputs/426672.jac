"""Convert arguments for slider and arrowbox command into comment string
for config file."""
def slider_command_to_str(arguments: list[str]) -> str {
    return '; '.join(arguments);
}