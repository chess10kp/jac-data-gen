"""
    A filename should have the following format:
    /path/to/file/filename_stem.jpg

    This function extracts filename_stem from the input filename string.

    """
def get_filename_stem(filename: str) -> str {
    parts = filename.split("/");
    return parts[-1].split(".")[0];
}