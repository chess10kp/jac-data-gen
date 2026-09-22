"""Converts argument name into a command line parameter."""
def _construct_param(arg_name: str) -> str {
    return f'--{arg_name.replace("_", "-")}';
}