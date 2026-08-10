"""
    Returns a query item matching messages that have certain recipients in
    the cc field.

    Args:
        recipient (str): The recipient in the cc field to match.

    Returns:
        The query string.

    """
def _cc(recipient: str) -> str {
    f"cc:{recipient}"
}