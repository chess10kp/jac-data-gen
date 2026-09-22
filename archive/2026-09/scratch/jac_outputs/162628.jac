""" convert list of hex strings into list of ints """
def str_to_int(string_list: Any) -> object {
    int_list = [int(x, 16) for x in string_list];
    return int_list;
}