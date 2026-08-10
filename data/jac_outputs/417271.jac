"""Return the top three scores in descending order."""
def personal_top_three(scores: list[int]) -> list[int] {
    return sorted(scores, reverse=True)[:3];
}