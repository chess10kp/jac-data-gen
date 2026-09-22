def zeroOut(data: list[list[int | str]]) -> list[list[int | str]] {
    cols = len(data[0]);
    flat = [0 if col == '' else col for row in data for col in row];
    return [flat[y:y + cols] for y in range(0, len(flat), cols)];
}