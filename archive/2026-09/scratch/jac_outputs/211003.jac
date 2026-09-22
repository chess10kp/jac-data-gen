"""Uses single line comments as we can't know if there are string escapes such as /* in the code."""
def function_comments(f: Callable[..., object]) -> str {
    try {
        return '\n'.join(["//" + line.strip() for line in (f.__doc__ as str).splitlines()]);
    } except AttributeError {
        return "// No Comment";
    }
}