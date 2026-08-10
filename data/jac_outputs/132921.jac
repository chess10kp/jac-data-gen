"""Method 2 recursively find the method."""
def recursively_find_changes(s: int, token: list[int]) -> int {
    if len(token) == 1 {
        return 1 if s % token[0] == 0 else 0;
    }
    count = 0;
    for i in range(int(s / token[0]) + 1) {
        count = count + recursively_find_changes(s - i * token[0], token[1:]);
    }
    return count;
}