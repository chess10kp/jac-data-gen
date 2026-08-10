"""Return custom 500 error."""
def application_error(e: str | Exception) -> tuple[str, int] {
    return ('Application error: {}'.format(e), 500);
}