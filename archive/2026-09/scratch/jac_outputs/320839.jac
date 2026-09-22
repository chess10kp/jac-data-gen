"""Get the UTF-8 bytes encoding an unicode character

    Parameters:
        char: unicode character

    Returns: integer array of the UTF-8 encoding
    """
def get_utf8_bytes(char: Any) -> object {
    c = ord(char);
    assert (c < 131072);
    if (c < 128) {
        return [c];
    } elif (c < 2048) {
        return [(192 + (c >> 6)), (128 + (c & 63))];
    } elif (c < 65536) {
        return [(224 + (c >> 12)), (128 + ((c >> 6) & 63)), (128 + (c & 63))];
    } else {
        return [
            (240 + (c >> 18)),
            (128 + ((c >> 12) & 63)),
            (128 + ((c >> 6) & 63)),
            (128 + (c & 63))
        ];
    }
}