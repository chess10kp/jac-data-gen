"""Return empty strings for undefined template variables."""
def finalize_variable_expression(result: str | None) -> str {
    return '' if result is None else result;
}