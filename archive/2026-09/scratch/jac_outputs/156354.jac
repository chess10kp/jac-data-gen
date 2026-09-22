"""Returns the mode of a unimodal distribution."""
def mode(data: list[int | str]) -> int | str | None {
    frequencies: dict[int | str, int] = {};
    maximum = 0;
    mode = None;
    for x in data {
        try {
            frequencies[x] += 1;
        } except KeyError {
            frequencies[x] = 1;
        }
        if frequencies[x] > maximum {
            mode = x;
            maximum = frequencies[x];
        }
    }
    return mode;
}