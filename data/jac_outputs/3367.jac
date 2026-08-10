"""Returns the mode of a list of numbers."""
def mode(lyst: list[int]) -> int {
    counts: dict[int, int] = {};
    for number in lyst {
        freq = counts.get(number, None);
        if freq is None {
            counts[number] = 1;
        } else {
            counts[number] = freq + 1;
        }
    }
    if len(counts) == 0 {
        return 0;
    } else {
        maximum = max(counts.values());
        for key in counts {
            if counts[key] == maximum {
                return key;
            }
        }
        return 0;
    }
}