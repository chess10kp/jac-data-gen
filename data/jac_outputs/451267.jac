"""Increments duplicates in an array until there are no duplicates."""
def increment_duplicates(arr: list[int]) -> list[int] {
    seen = set();
    for i in range(len(arr)) {
        while arr[i] in seen {
            arr[i] += 1;
        }
        seen.add(arr[i]);
    }
    return arr;
}