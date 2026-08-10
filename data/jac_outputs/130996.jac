"""Return a custom 500 error."""
def application_error(e: Exception) -> tuple[str, int] {
    return ('Sorry, unexpected error: {}'.format(e), 500);
}