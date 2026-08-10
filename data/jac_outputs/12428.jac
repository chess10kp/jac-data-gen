"""Return the number of ways in which s can be partitioned into two
sublists that have sums within d of each other."""
def num_splits(s: list[int], d: int) -> int {
    def helper(s: list[int], diff: int) -> int {
        if not s {
            return 1 if abs(diff) <= d else 0;
        }
        first_el = s[0];
        rest = s[1:];
        return helper(rest, diff + first_el) + helper(rest, diff - first_el);
    }
    return helper(s, 0) // 2;
}