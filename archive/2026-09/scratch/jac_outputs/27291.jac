"""
    mode 0: splits an ascii string and adds elements to a list.
    mode 1: converts list elements to ascii characters and joins them.
    """
def str_list(data_in: str | list[int], mode: int = 0) -> list[int] | str {
    if mode == 0 {
        s = data_in as str;
        return [ord(c) for c in s];
    }
    chars = data_in as list[int];
    data_out = '';
    for i in range(16) {
        data_out += chr(chars[i]);
    }
    return data_out;
}