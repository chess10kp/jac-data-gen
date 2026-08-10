""" Convert array of uint8_t into a single Python number """
def uint8array_to_number(uint8array: list[int]) -> int {
    return sum([x << (i * 8) for (i, x) in enumerate(uint8array)]);
}