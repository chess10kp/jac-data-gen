"""
Detects whether a bytes object represents an integer.
"""
def is_serialised(serialised: bytes) -> bool {
    first_byte = True;
    for byte in serialised {
        if not (48 <= byte <= 57) and not (first_byte and byte == 45) {
            return False;
        }
        first_byte = False;
    }
    return not first_byte;
}