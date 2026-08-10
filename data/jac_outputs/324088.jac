"""True if the given file path is a baseline file."""
def check(file_path: str) -> bool {
    file_path.endswith('.baseline')
}