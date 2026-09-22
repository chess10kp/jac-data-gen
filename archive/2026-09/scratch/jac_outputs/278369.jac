"""
    Merges two lists alternately.

    E.g.:

    first = [1, 2]
    second = ["A", "B"]

    result = [1, "A", 2, "B"]
    """
def merge_lists(first: Any, second: Any) -> object {
    return [item for pair in zip(first, second) for item in pair];
}