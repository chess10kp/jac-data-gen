glob UINT8_MASK = 0xFF;
glob UINT16_MAX = 65535;

"""Converts a single integer number to an list with the length 2 with highest byte first."""
def int_to_bytes(integer_value: int) -> list[int] {
    if not isinstance(integer_value, int) or integer_value < 0 or integer_value > UINT16_MAX {
        raise ValueError(
            f'integer_value to be packed must be unsigned short: [0-65535]! value was {integer_value}'
        );
    }
    return [(integer_value >> 8) & UINT8_MASK, integer_value & UINT8_MASK];
}