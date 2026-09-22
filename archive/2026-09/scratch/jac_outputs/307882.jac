"""Remove PKCS#7 padding."""
def unpad(data: str | bytes) -> bytearray {
    array = bytearray();
    array.extend(data);
    array = array[:-array[-1]];
    return array;
}