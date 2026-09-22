"""Return string representation of a list of integers,
    using ``,`` as a separator and ``:`` as a range separator.
    """
def _format_number_list(number_list: list[int]) -> str {
    ret = "";
    first_in_range = number_list[0];
    last_in_range = number_list[0];
    previous = number_list[0];
    for number in number_list[1:] {
        if number - previous != 1 {
            if last_in_range > first_in_range {
                ret += "%d:%d," % (first_in_range, last_in_range);
            } else {
                ret += "%d," % previous;
            }
            first_in_range = number;
            last_in_range = number;
        } else {
            last_in_range = number;
        }
        previous = number;
    }
    if last_in_range > first_in_range {
        ret += "%d:%d" % (first_in_range, last_in_range);
    } else {
        ret += "%d" % previous;
    }
    return ret;
}