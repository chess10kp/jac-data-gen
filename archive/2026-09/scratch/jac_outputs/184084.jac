"""Get the name of the file without the extension"""
def get_prefix(filename: str) -> str {
    return filename.split(".")[0];
}