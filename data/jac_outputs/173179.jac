"""This will find the duplicated int in the list."""
def find_dup(arr: list[int]) -> int {
    dup = set([x for x in arr if arr.count(x) > 1]);
    answer = list(dup);
    return answer[0];
}