"""Returns the fileextension of a given file name."""
def getFileExt(fileName: str) -> str {
    last_dot = fileName.rindex(".");
    return fileName[last_dot:];
}