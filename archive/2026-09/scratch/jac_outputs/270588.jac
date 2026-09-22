"""
    return a base expansion
    """
def base_expansion(num: int, base: int = 2) -> int {
    q = int(num);
    b = int(base);
    count = 0;
    expansion = [];
    while q != 0 {
        expansion.append(q % b);
        q = q // b;
        count += 1;
    }
    expansion.reverse();
    res = "".join(map(str, expansion));
    return int(res);
}