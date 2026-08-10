glob BYTE_MASK = 0xFF;

"""Convert a byte-string to a signed integer."""
def bin2sint(data: bytes) -> int {
    number = 0;
    arr = list(data);
    byteslen = len(data);
    negative = arr[byteslen - 1] >= 128;
    for (idx, byte_val) in enumerate(arr) {
        if negative {
            byte_val = byte_val ^ BYTE_MASK;
        }
        number += byte_val * (256 ** idx);
    }
    if negative {
        number = (number + 1) * -1;
    }
    return number;
}