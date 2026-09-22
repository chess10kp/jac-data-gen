""" Returns true if sub_list is already appended to the main_list. Otherwise returns false"""
def element_exist_in_list(main_list: list[list[int]], sub_list: list[int]) -> bool {
    try {
        _ = main_list.index(sub_list);
        return True;
    } except ValueError {
        return False;
    }
}