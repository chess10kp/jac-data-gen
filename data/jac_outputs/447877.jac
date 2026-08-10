"""string = Int2AP(num)
    Return 'num' converted to bytes using characters from the set 'A'..'P'
    """
def Int2AP(num: Any) -> object {
    val = b'';
    AP = b'ABCDEFGHIJKLMNOP';
    num = int(abs(num));
    while num {
        (num, mod) = divmod(num, 16);
        val = AP[mod:(mod + 1)] + val;
    }
    return val;
}