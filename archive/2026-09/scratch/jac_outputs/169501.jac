"""Return a command line prefaced with a timeout wrappers and stdout/err unbuffered."""
def timeout_cmd(cmd: str, timeout: int) -> str {
    return 'timeout -sKILL %us stdbuf -o0 -e0 %s' % (timeout, cmd);
}