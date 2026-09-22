"""
    Check if any items in list1 are in list2
    :param list1: list
    :param list2: list
    :return:
    """
def in_any_list(list1: Any, list2: Any) -> object {
    list1 = list1.split(" ") if isinstance(list1, str) else list1;
    list2 = list2.split(" ") if isinstance(list2, str) else list2;
    return `any((i in list2) for i in list1);
}