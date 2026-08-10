"""
    Return xor of two hex strings.

    An XOR of two pieces of data will be as random as the input with the most randomness.
    We can thus combine two entropy sources in this way as a safeguard against one source being
    compromised in some way.
    For details, see http://crypto.stackexchange.com/a/17660

    returns => <string> in hex format
    """
def xor_hex_strings(str1: Any, str2: Any) -> object {
    if (len(str1) != len(str2)) {
        raise Exception("tried to xor strings of unequal length");
    }
    str1_dec = int(str1, 16);
    str2_dec = int(str2, 16);
    xored = str1_dec ^ str2_dec;
    return "{:0{}x}".format(xored, len(str1));
}