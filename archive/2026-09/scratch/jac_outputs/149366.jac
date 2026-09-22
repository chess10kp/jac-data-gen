"""Get string representation containing the reference to a variable with
given name. This string is intended to be used as a template parameter
reference within workflow specifications in workflow templates."""
def VARIABLE(name: str) -> str {
    return '$[[{}]]'.format(name);
}