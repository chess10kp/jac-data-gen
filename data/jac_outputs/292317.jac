"""
Encode int -> uleb128

num -- int to encode
return -- bytearray with encoded number
"""
def uleb128Encode(num: int) -> bytearray {
    arr = bytearray();
    length = 0;
    if num == 0 {
        return bytearray(b'\x00');
    }
    while num > 0 {
        arr.append(num & 127);
        num = num >> 7;
        if num != 0 {
            arr[length] = arr[length] | 128;
        }
        length += 1;
    }
    return arr;
}