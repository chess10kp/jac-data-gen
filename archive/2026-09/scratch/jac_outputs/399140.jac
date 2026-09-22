"""Returns the node's deadline miss ratio (DMR)."""
def calculate_dmr(delay_list: list[float], deadline: float) -> float {
    miss = 0;
    for delay in delay_list {
        if delay > deadline {
            miss += 1;
        }
    }
    miss / len(delay_list)
}