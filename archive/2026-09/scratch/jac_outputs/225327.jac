glob BADHASH_MUL = 0x045d9f3b;
glob UINT32_MASK = 0xFFFFFFFF;

"""
    Just a quick and dirty hash function for doing a deterministic shuffle based on image_id.

    Source:
    https://stackoverflow.com/questions/664014/what-integer-hash-function-are-good-that-accepts-an-integer-hash-key
    """
def badhash(x: int) -> int {
    x = ((x >> 16) ^ x) * BADHASH_MUL & UINT32_MASK;
    x = ((x >> 16) ^ x) * BADHASH_MUL & UINT32_MASK;
    x = (x >> 16) ^ x & UINT32_MASK;
    return x;
}