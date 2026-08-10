"""
    Converts data from a Roblox macOS .plist file into a dictionary.
    """
def plist_data_to_rbx_dict(plist_data: dict) -> dict {
    rbx_dict: dict = {};
    for (raw_key, raw_value) in plist_data.items() {
        split_key = raw_key.split(".");
        key_piece = rbx_dict;
        for (i, key_bit) in enumerate(split_key) {
            key_bit = key_bit.replace("\u00b7", ".");
            if (i == (len(split_key) - 1)) {
                if isinstance(raw_value, `bytes) {
                    raw_value = str(raw_value);
                }
                key_piece[key_bit] = raw_value;
                continue;
            }
            if key_piece.get(key_bit) {
                key_piece = key_piece[key_bit];
            } else {
                new_piece = {};
                key_piece[key_bit] = new_piece;
                key_piece = new_piece;
            }
        }
    }
    return rbx_dict;
}