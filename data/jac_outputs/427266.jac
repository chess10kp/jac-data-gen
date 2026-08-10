"""An easy-to-read error message for assert"""
def show_run_error(exit_status: int, output: str) -> str {
    return 'Failed with exit status %s\n' '--------------\n' '%s' % (exit_status, output);
}