"""
    Finds and returns the length of the longest string in list
    Parameter: (list) containing strings
    Return: (int) length of longest string in list
    """
def findMinWidth(list: list[str | int | float]) -> int {
    longest = "";
    for item in list {
        item = str(item);
        if len(longest) < len(item) {
            longest = item;
        }
    }
    return len(longest);
}