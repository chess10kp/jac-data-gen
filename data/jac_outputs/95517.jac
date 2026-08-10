"""Minimum bribes to sort a queue via iterative bubble-style moves."""
def minimumBribes_iterative(q: list[int]) -> int {
    length = len(q);
    moves = [0 for i in range(length)];
    moves_made = 0;
    arr = q.copy();
    last_pos = length - 1;
    def get_pos_indices(arr: list[int]) -> int | None {
        while last_pos >= 0 and arr[last_pos] <= last_pos + 1 {
            last_pos -= 1;
        }
        if last_pos == -1 {
            return None;
        }
        last_pos += 1;
        return last_pos - 1;
    }
    while True {
        pos = get_pos_indices(arr);
        if pos is None {
            break;
        } else {
            thing = arr[pos];
            moves[thing - 1] += 1;
            moves_made += 1;
            if moves[thing - 1] == 3 {
                return -1;
            }
            arr = arr[:pos] + [arr[pos + 1]] + [thing] + arr[pos + 2:];
        }
    }
    return moves_made;
}