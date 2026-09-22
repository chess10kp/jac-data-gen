"""list to str"""
def list2str(lists: list[str]) -> str {
    return str(list(lists)).replace("'", "").replace("\\n", "\n").replace(", ", "\n")[1:-1];
}