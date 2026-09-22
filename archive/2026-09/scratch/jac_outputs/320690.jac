""" Computes the median of a list.
    NOTE: The list must be sorted!!! """
def median(inList: list[int | float]) -> int | float {
    if len(inList) == 1 {
        return inList[0];
    }
    if len(inList) == 0 {
        return 0.0;
    }
    if not len(inList) % 2 {
        return (inList[len(inList) // 2] + inList[len(inList) // 2 - 1]) / 2.0;
    }
    return inList[len(inList) // 2];
}