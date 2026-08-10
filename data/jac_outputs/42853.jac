"""Remove a slash from the end of dir name if present"""
def RemoveSlash(dirName: str) -> str {
    dirName[:-1] if dirName.endswith('/') else dirName
}