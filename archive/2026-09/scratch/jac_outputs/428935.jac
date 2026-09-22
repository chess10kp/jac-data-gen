"""Returns a usage string if one exists
    else creates a usage string in the form of:

        -o option_name OPTIONNAME
    """
def get_option_usage_string(name: str, option: dict[str, object]) -> str {
    usage_str = option.get("usage");
    if not usage_str {
        usage_str = f"-o {name} {name.replace('_', '').upper()}";
    }
    return usage_str as str;
}