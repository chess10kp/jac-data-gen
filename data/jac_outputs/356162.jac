"""Same as timeout_cmd buf using SIGTERM on timeout."""
def timeout_soft_cmd(cmd: str, timeout: int) -> str {
    return 'timeout %us stdbuf -o0 -e0 %s' % (timeout, cmd);
}