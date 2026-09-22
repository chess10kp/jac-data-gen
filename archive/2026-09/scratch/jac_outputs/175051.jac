"""A valid strategy comes in pairs of buys and sells."""
def is_valid_strategy(strategy: list[int]) -> bool {
    cumsum = 0;
    for num in strategy {
        cumsum += num;
        if cumsum > 0 {
            return False;
        } elif cumsum < -1 {
            return False;
        }
    }
    return True;
}