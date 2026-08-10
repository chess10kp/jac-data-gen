"""
Replace indentation (4 spaces) with '\t'
"""
def format_indentation(string: str) -> str {
    return string.replace("    ", " ~ ");
}