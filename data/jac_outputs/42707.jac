"""Word list (16 bits int) to long list (32 bits int)

        By default word_list2long() use big endian order. For use little endian, set
        big_endian param to False.

        :param val_list: list of 16 bits int value
        :type val_list: list
        :param big_endian: True for big endian/False for little (optional)
        :type big_endian: bool
        :returns: 2's complement result
        :rtype: list
    """
def word_list_to_long(val_list: Any, big_endian: Any = True) -> object {
    long_list = [None] * int((len(val_list) / 2));
    for (i, item) in enumerate(long_list) {
        if big_endian {
            long_list[i] = (val_list[(i * 2)] << 16) + val_list[((i * 2) + 1)];
        } else {
            long_list[i] = (val_list[((i * 2) + 1)] << 16) + val_list[(i * 2)];
        }
    }
    return long_list;
}