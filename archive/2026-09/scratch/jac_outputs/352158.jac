"""Return the average value of the list, or -1 on error."""
def get_lst_avg(lst: list[float | int]) -> float {
    try {
        return sum(lst) / float(len(lst));
    } except TypeError {
        print(
            "get_lst_avg: bad lst or list contains non-numeric values (None, str, etc.)"
        );
    } except ZeroDivisionError {
        ;
    }
    return -1;
}