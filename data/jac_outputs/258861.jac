"""Search a number in a list using binary search."""
def search(target: int, prime_list: list[int]) -> bool {
    (left, right) = (0, len(prime_list) - 1);
    while left <= right {
        middle = (left + right) // 2;
        if prime_list[middle] == target {
            return True;
        } elif prime_list[middle] < target {
            left = middle + 1;
        } else {
            right = middle - 1;
        }
    }
    return False;
}