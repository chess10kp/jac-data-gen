"""Return all subsets of a set (power set)."""
def power_set(arr: list[int]) -> list[list[int]] {
    if len(arr) == 0 {
        return [[]];
    }
    (head, tail) = (arr[0], arr[1:]);
    tail_subsets = power_set(tail);
    head_subsets = [];
    for sub in tail_subsets {
        new_sub = sub[:];
        new_sub.append(head);
        head_subsets.append(new_sub);
    }
    return tail_subsets + head_subsets;
}