"""convert int to binary string of given length."""
def int_to_bin(num_int: int, length: int) -> str {
    num_str = bin(num_int)[2:];
    str_len = len(num_str);
    if length <= str_len {
        return num_str[str_len - length:str_len];
    } else {
        return num_str.zfill(length);
    }
}