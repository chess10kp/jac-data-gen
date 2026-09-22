"""Exracts the encode dict when it has been encoded to a file.
    dict_dict contains the bytes string that is between 'DICT_START'
    and 'DICT_END' in the file."""
def bytes_to_encode_dict(dict_bytes: bytes) -> dict[int, str] {
    ret = dict();
    d = dict_bytes.decode("utf-8");
    pairs = d.split(",");
    for pair in pairs {
        (key, value) = pair.strip().split(": ");
        ret[int(key)] = value.replace("'", "");
    }
    return ret;
}