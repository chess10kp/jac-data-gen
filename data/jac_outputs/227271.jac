glob EXECUTABLE_FLAG = 0x49;

"""Takes a number containing a Unix file permission mode (as reported by RPM utility)
and returns True if the file has executable bit set.

NOTE: for some reason the modes returned by RPM utility are beyond 777 octal number...
so we throw away the additional bits.
"""
def is_executable(permission_int: int) -> bool {
    return (permission_int & EXECUTABLE_FLAG) != 0;
}