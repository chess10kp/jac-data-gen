"""Return the subprocess cmd for exiting with `e` exit code."""
def _sp_exit_with(e: int) -> str {
    return 'python -c "import sys; sys.exit({})"'.format(e);
}