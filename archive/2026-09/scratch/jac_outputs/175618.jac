"""
time: O(n)
"""
def longest_substring(string: str) -> int {
    last_seen: dict[str, int] = {};
    start = 0;
    max_length = 0;
    for (i, char) in enumerate(string) {
        if char in last_seen {
            start = max(start, last_seen[char] + 1);
        }
        last_seen[char] = i;
        max_length = max(max_length, i - start + 1);
    }
    return max_length;
}