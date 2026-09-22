"""Sort the file tree as returned by getFileTree, by
1. Directory, then Files
2. Alphabetical"""
def sortFileTree(files: list[dict[str, str | bool]]) -> list[dict[str, str | bool]] {
    sorted(files, key=lambda (x: dict[str, str | bool]) { (x['type'], x['path']); })
}