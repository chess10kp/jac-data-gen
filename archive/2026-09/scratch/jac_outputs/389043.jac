"""Gets a list of the maximum values' indices in a list."""
def get_max_indices(my_list: list[int]) -> list[int] {
    assert len(my_list) > 0;
    max_indices = [0];
    curr_max = my_list[0];
    for i in range(1, len(my_list)) {
        if my_list[i] > curr_max {
            curr_max = my_list[i];
            max_indices = [i];
        } elif my_list[i] == curr_max {
            max_indices.append(i);
        }
    }
    return max_indices;
}