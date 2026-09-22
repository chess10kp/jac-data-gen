"""Calculate the cumulative gain based on the rank list and return a list."""
def cumulative_gain(rank_list: list[int]) -> list[int] {
    cumulative = [rank_list[0]];
    for i in range(1, len(rank_list)) {
        cumulative.append(cumulative[i - 1] + rank_list[i]);
    }
    return cumulative;
}