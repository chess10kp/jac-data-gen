"""Converts  ['0001', '0202', '0203', '0204',...] to [1, 202, 203, 204,...]"""
def list_of_int_from_list_of_str(list_str: list[str]) -> list[int] {
    return [int(s) for s in list_str];
}