""" 'ff' -> 255 ; 'af fe' -> [175, 254] ; ('af', 'fe) -> [175, 254] """
def hex_to_dec(value: Any) -> object {
    if (`type(value) in (`list, `tuple)) {
        return [hex_to_dec(item) for item in value];
    } else {
        value = value.split(' ');
        if (len(value) == 1) {
            return int(str(value[0]), 16);
        } else {
            return hex_to_dec(value);
        }
    }
}