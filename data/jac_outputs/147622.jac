"""Count strings in str_seq that start with prefix."""
def count_common_prefix(str_seq: list[str], prefix: str) -> int {
    return sum(elem.startswith(prefix) for elem in str_seq);
}