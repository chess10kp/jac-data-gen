"""
    :param min_size lower bound of the interval to divide into bins
    :param max_size upper bound of the interval to divide into bins
    :param bin_no the interval will be divided into that many bins
    :returns list of tuples, representing the lower and upper limits of each subinterval after dividing into bins

    This function separates the input interval into bins
    """
def binner(min_size: Any, max_size: Any, bin_no: Any) -> object {
    bin_size = float((max_size - min_size)) / float(bin_no);
    Bins = [
        ((min_size + (bin_size * k)), (min_size + (bin_size * (k + 1))))
        for k in range(0, bin_no)
    ];
    return Bins;
}