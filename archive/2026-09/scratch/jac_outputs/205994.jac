"""Handle general JbossAS warning and return exit code."""
def _exit_with_general_warning(exc: BaseException) -> int | SystemExit {
    if isinstance(exc, SystemExit) {
        return exc;
    }
    print("WARNING - General JbossAS warning:", exc);
    return 1;
}