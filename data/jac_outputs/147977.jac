"""Extends path through block and returns true if the way is blocked"""
def extend_path(
    start_el: tuple[int, int] | None,
    block: list[list[str]],
    queue: list[tuple[int, int]],
    is_lateral: bool
) -> bool {
    next_el = start_el;
    h = len(block);
    w = len(block[0]);
    while next_el is not None {
        current = next_el;
        next_el = None;
        for i in range(-1, 2) {
            add_to_height = i if is_lateral else 1;
            add_to_width = i if not is_lateral else 1;
            candidate = (current[0] + add_to_height, current[1] + add_to_width);
            if candidate[0] < 0 or candidate[0] >= h or candidate[1] < 0 or candidate[1] >= w {
                continue;
            }
            if block[candidate[0]][candidate[1]] == '#' {
                if (is_lateral and candidate[1] == w - 1) or (not is_lateral and candidate[0] == h - 1) {
                    return True;
                } elif next_el is None {
                    next_el = candidate;
                } else {
                    queue.append(candidate);
                }
            }
        }
    }
    return False;
}