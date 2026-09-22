"""
    An option validator for parsing a comma-separated option argument.  Similar to
    the validators found in `docutils.parsers.rst.directives`.
    """
def option_str_list(argument: str | None) -> list[str] {
    if argument is None {
        raise ValueError("argument required but none supplied");
    }
    return [s.strip() for s in argument.split(",")];
}