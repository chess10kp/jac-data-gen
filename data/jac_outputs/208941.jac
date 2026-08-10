"""Detect binary object beginnings, ends, and lengths in a !d signal."""
def detect_binary_blocks(vec_bin: list[bool]) -> tuple[list[int], list[int], list[int]] {
    (begins, ends, lengths) = ([], [], []);
    if vec_bin[0] {
        begins.append(0);
    }
    length = 0;
    for i in range(1, len(vec_bin)) {
        if vec_bin[i] > vec_bin[i - 1] {
            begins.append(i);
        } elif vec_bin[i] < vec_bin[i - 1] {
            ends.append(i);
            lengths.append(length);
            length = 0;
        } elif vec_bin[i] == 1 {
            length += 1;
        }
    }
    if vec_bin[-1] {
        ends.append(len(vec_bin) - 1);
        lengths.append(length);
    }
    return (begins, ends, lengths);
}