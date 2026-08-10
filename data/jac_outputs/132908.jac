"""For a list, remove value in [" ",""]."""
def getMissingIndex(x: list[str]) -> tuple[list[int], list[str]] {
    empty_index = [
        i
        for (i, elem) in enumerate(x)
        if elem in [" ", ""]
    ];
    for i in empty_index {
        x[i] = "..";
    }
    return (empty_index, x);
}