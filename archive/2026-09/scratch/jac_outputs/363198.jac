"""Recursive implementation of Josephus problem — return the safe survivor position."""
def josephus(num: int, k: int) -> int {
    if num == 1 {
        return 1;
    }
    return (josephus(num - 1, k) + k - 1) % num + 1;
}