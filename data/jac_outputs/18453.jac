"""Read variable length encoded 128 bits unsigned integer."""
def unsigned_leb128_decode(data: Iterator[int]) -> int {
    result = 0;
    shift = 0;
    while True {
        byte: int = next(data);
        result |= (byte & 127) << shift;
        if (byte & 128) == 0 {
            break;
        }
        shift += 7;
    }
    return result;
}