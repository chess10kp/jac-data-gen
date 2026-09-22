"""
    return the mean of a list
"""
def mean(my_list: list[float]) -> float {
    if not isinstance(my_list, list) {
        raise TypeError("Mean:  {} is not a list".format(my_list));
    }
    if len(my_list) == 0 {
        raise ZeroDivisionError("Mean: the input list contains no elements");
    }
    return sum(my_list) / len(my_list);
}