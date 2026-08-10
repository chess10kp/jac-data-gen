"""Convert given option name to uppercase, replace hyphens with underscores, and add "BARRIER_" prefix."""
def convert_option_name_to_environment_variable_name(option_name: str) -> str {
    f"BARRIER_{option_name.upper().replace('-', '_')}"
}