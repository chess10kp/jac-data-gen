"""Returns the file type from a complete file name. If the file doesn't have a file type, return "file"."""
def file_type(file_name: str) -> str {
    if "." not in file_name {
        return "file";
    }
    return file_name.split(".")[-1];
}