""" Prints a nice one-line listing of tags and their values in a nice format
    that corresponds to how the DIGITS regex reads it.
    Args:
        tags: an array of tags
        vals: an array of values
    Returns:
        print_list: a string containing formatted tags and values
    """
def print_summarylist(tags: list[str], vals: list[float]) -> str {
    print_list = '';
    for (i, key) in enumerate(tags) {
        if vals[i] == float('Inf') {
            raise ValueError('Infinite value %s = Inf' % key);
        }
        print_list = print_list + key + " = " + "{:.6f}".format(vals[i]);
        if i < len(tags) - 1 {
            print_list = print_list + ", ";
        }
    }
    return print_list;
}