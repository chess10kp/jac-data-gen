"""
    Convert ``num`` of int type to list of length ``len_`` with 0's and 1's.
    ``num`` and ``len_`` have to non-negative.

    For e.g., ``num`` = `5`; `int2bin(num`, ``len_`` =4) = `[0, 1, 0, 1]`.

    For e.g., ``num`` = `12`; `int2bin(num`, ``len_`` =3) = `[1, 0, 0]`.

    Input
    -----
        num: int
            An integer to be converted into binary representation.

        len_: int
            An integer defining the length of the desired output.

    Output
    -----
        : list of int
            Binary representation of ``num`` of length ``len_``.
    """
def int2bin(num: Any, len_: Any) -> object {
    assert (num >= 0) , "Input integer should be non-negative";
    assert (len_ >= 0) , "width should be non-negative";
    bin_ = format(num, f'0{len_}b');
    binary_vals = [int(x) for x in bin_[-len_:]] if len_ else [];
    return binary_vals;
}