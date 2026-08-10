"""This function returns the number of keys pressed during a run, because why not."""
def get_key_presses(songs: int, data: list[int], replay: bool) -> int {
    _ = replay;
    if songs < 0 {
        return 0;
    }
    keys = 0;
    for i in range(songs) {
        keys += int(data[(i + 1) * 11]);
    }
    return keys;
}