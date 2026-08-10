"""
    listA: a list of numbers
    listB: a list of numbers of the same length as listB

    Returns the dot product of all the numbers in the lists.
    """
def dotProduct(listA: Any, listB: Any) -> object {
    dotProd = 0;
    for num in range(len(listA)) {
        prod = listA[num] * listB[num];
        dotProd = dotProd + prod;
    }
    return dotProd;
}