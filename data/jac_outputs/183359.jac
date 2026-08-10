"""Sanitize a string to be used as a filename"""
def CleanStrForFilenames(filename: str) -> str {
    keepcharacters = (' ', '.', '_');
    return "".join(
        c for c in filename if c.isalnum() or c in keepcharacters
    ).rstrip();
}