"""Crappy implementation of creating a Set from a List.  To cope with older Python versions"""
def to_set(list: Any) -> object {
    temp_dict = {};
    for `entry in list {
        temp_dict[`entry] = "dummy";
    }
    return temp_dict.keys();
}