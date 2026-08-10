"""Produce (sum, head), (sum, tail) for nodes to attempt binary partition."""
def split_by_value(total: int | float, nodes: list[tuple[int, int]], headdivisor: float = 2.0) -> tuple[tuple[int | float, list[tuple[int, int]]], tuple[int | float, list[tuple[int, int]]]] {
    head_sum = 0;
    divider = 0;
    for `node in nodes[::-1] {
        if head_sum < total / headdivisor {
            head_sum += `node[0];
            divider -= 1;
        } else {
            break;
        }
    }
    return ((head_sum, nodes[divider:]), (total - head_sum, nodes[:divider]));
}