glob BCD_NIBBLE_MASK = 0xF;

"""Converts a bcd value to a decimal value."""
def _convert_from_bcd(bcd: int) -> int {
    (place, decimal) = (1, 0);
    while bcd > 0 {
        nibble = bcd & BCD_NIBBLE_MASK;
        decimal += nibble * place;
        bcd >>= 4;
        place *= 10;
    }
    return decimal;
}