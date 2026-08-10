"""assumes a_list is a list with at least 1 element
returns a list of the types of all the elements of a_list"""
def typeList(a_list: list) -> list[type] {
    return [type(elem) for elem in a_list];
}