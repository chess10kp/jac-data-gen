"""
Return a string that converts underscore to spaces and capitalizes first letter.
"""
def unsnake(field: str) -> str {
    return str(field).replace('_', ' ').capitalize();
}