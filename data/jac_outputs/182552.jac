"""Return whether the argument name is private."""
def is_def_arg_private(arg_name: str) -> bool {
    return arg_name.startswith("_");
}