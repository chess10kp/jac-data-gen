"""Compares follower count key between two dictionaries."""
def higher_follower_count(A: dict[str, int], B: dict[str, int]) -> str {
    if A['follower_count'] >= B['follower_count'] {
        return "A";
    }
    return "B";
}