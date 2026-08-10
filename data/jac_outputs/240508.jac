"""
Check that a pid is of type str. Pids are generated as uuid4, and this
check is done to make sure the programmer has converted it to a str before
attempting to use it with the DataONE client.
"""
def check_pid(pid: str | int) -> str {
    if not isinstance(pid, str) {
        return str(pid);
    }
    return pid;
}