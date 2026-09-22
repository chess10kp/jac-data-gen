"""Partition list around first element; return rearranged list and key index."""
def quick_one(lis: list[int]) -> tuple[list[int], int] {
    n_list = lis.copy();
    key = lis[0];
    key_i = 0;
    p_min = 0;
    p_max = len(lis) - 1;
    while p_min != p_max {
        while p_max > key_i {
            if n_list[p_max] <= key {
                (n_list[p_max], n_list[key_i]) = (n_list[key_i], n_list[p_max]);
                key_i = p_max;
                break;
            }
            p_max -= 1;
        }
        while p_min < key_i {
            if n_list[p_min] > key {
                (n_list[p_min], n_list[key_i]) = (n_list[key_i], n_list[p_min]);
                key_i = p_min;
                break;
            }
            p_min += 1;
        }
    }
    return (n_list, key_i);
}