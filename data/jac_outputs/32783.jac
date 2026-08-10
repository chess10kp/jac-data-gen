""" Converts a string of binary numbers to their two's compliment integer representation """
def convert_twos_compliment(bin_str: Any) -> object {
    length = len(bin_str);
    if (bin_str[0] == '0') {
        return int(bin_str, 2);
    } else {
        return (int(bin_str, 2) - (1 << length));
    }
}