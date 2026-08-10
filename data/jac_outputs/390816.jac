"""Recreate tags from a list of tuples into the Amazon Tag format.
    Args:
        list_of_tags (list): List of tuples.

    Basic Usage:
        >>> list_of_tags = [('Env', 'Development')]
        >>> recreate_tags_from_list(list_of_tags)
        [
            {
                "Value": "Development",
                "Key": "Env"
            }
        ]

    Returns:
        List
    """
def recreate_tags_from_list(list_of_tags: list[tuple[str, str]]) -> list[dict[str, str]] {
    [{'Key': key_name, 'Value': key_val} for (key_name, key_val) in list_of_tags]
}