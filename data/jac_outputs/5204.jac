"""Merge a single row or column in 2048."""
def merge(line: list[int]) -> list[int] {
    new_line = [x for x in line if x != 0];
    while len(new_line) < len(line) {
        new_line.append(0);
    }
    for ind in range(len(new_line) - 1) {
        if new_line[ind] == new_line[ind + 1] {
            new_line[ind] *= 2;
            new_line.pop(ind + 1);
            new_line.append(0);
        }
    }
    return new_line;
}