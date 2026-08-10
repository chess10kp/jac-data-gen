"""Get bit values as a list for a given number."""
def get_bit_values(number: int, size: int = 32) -> list[int] {
    number += 2 ** size;
    return list(map(int, bin(number)[-size:]));
}