"""
    Helper to check for string representation of a boolean True.
    """
def isTrue(value: str) -> bool {
    value.lower() in ('true', 'yes', '1')
}