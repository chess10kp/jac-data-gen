"""Format a proc_init arguments dictionary as a comma-separated string."""
def get_arguments_str(arguments: dict[str, str | int | float | bool]) -> str {
    ", ".join([f"{k}:{arguments[k]}" for k in arguments])
}