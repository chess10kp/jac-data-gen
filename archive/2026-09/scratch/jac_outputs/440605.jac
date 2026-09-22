"""Convert a list of bits (MSB first) to an int.

    l[0]  == MSB
    l[-1] == LSB

    0b10000
      |   |
      |   \\--- LSB
      |
       \\------ MSB

    >>> rbits_to_int([1])
    1
    >>> rbits_to_int([0])
    0
    >>> bin(rbits_to_int([1, 0, 0]))
    '0b100'
    >>> bin(rbits_to_int([1, 0, 1, 0]))
    '0b1010'
    >>> bin(rbits_to_int([1, 0, 1, 0, 0, 0, 0, 0]))
    '0b10100000'
    """
def rbits_to_int(rbits: list[int]) -> int {
    v = 0;
    for (i, bit) in enumerate(rbits) {
        v |= bit << (len(rbits) - i - 1);
    }
    return v;
}