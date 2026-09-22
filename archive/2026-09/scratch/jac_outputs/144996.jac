glob UINT8_MAX = 0xFF;
glob UINT16_MAX = 0xFFFF;
glob UINT24_MAX = 0xFFFFFF;
glob UINT32_MAX = 0xFFFFFFFF;

"""Converts an ASN1 Tag into the corresponding byte representation."""
def tagToByte(value: int) -> list[int] {
    if value <= UINT8_MAX {
        return [value];
    } elif value <= UINT16_MAX {
        return [(value >> 8), (value & 0xFF)];
    } elif value <= UINT24_MAX {
        return [(value >> 16), ((value >> 8) & 0xFF), (value & 0xFF)];
    } elif value <= UINT32_MAX {
        return [
            (value >> 24),
            ((value >> 16) & 0xFF),
            ((value >> 8) & 0xFF),
            (value & 0xFF)
        ];
    }
    raise Exception("tagToByte: tag is too big");
}