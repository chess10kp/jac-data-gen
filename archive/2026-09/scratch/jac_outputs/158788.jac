"""Calculate the margin distribution of classifier 2."""
def margin2(contingency_table: list[list[int]], i: int) -> int {
    return sum(contingency_table[i][j] for j in range(len(contingency_table)));
}