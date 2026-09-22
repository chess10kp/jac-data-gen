glob INT16_MAX = 0x7FFF;
glob UINT16_WRAP = 0x8000;
glob UINT16_MASK = 0xFFFF;

"""
Utility function to convert a hex string into a 16 bit signed hex integer value
"""
def convert_to_signed_int_16_bit(hex_str: str) -> int {
    val = int(hex_str, 16);
    if (val > INT16_MAX) {
        val = ((val + UINT16_WRAP) & UINT16_MASK) - UINT16_WRAP;
    }
    return val;
}