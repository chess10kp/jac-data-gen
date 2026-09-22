"""Generate the expected list of previous values given a list of next values."""
def generate_previous_list(next_list: list[int | None]) -> list[int | None] {
    previous_list = [None] + next_list[:-1];
    idx_last_valid = 1;
    for i in range(1, len(previous_list)) {
        if previous_list[i] is None {
            previous_list[i] = previous_list[idx_last_valid];
        } else {
            idx_last_valid = i;
        }
    }
    assert len(next_list) == len(previous_list);
    return previous_list;
}