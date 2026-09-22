"""
    BIG-O Notation = O(n)
    """
def sum_numbers_in_list(array: list[int]) -> int {
    result = 0;
    for i in array {
        result += i;
    }
    return result;
}