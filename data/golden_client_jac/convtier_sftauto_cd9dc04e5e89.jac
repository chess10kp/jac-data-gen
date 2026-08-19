"""
    Helper function to remove duplicates from a list while preserving order.
    """
def remove_duplicates(arr: Any) -> object {
    return `list(`dict.fromkeys(arr));
}



with entry {
    print(remove_duplicates('hello'));
    print(remove_duplicates('Racecar'));
    print(remove_duplicates('abcabc'));
}
