"""Checks '--<key>anything<value>' is in arg_list."""
def find_startswith_endswith(arg_list: list[str], key: str, value: str) -> bool {
    for arg in arg_list {
        if arg.startswith(key) and arg.endswith(value) {
            return True;
        }
    }
    return False;
}