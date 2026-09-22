"""Check whether the cache has this page number."""
def find_page(cache: list[int], refer_bit: list[int], page: int, frame_num: int) -> bool {
    for frame in range(frame_num) {
        if cache[frame] == page {
            refer_bit[frame] = 1;
            return True;
        }
    }
    return False;
}