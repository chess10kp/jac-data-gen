"""rolls a list to the right
e.g.: roll([0,1,1]) => [1,0,1]"""
def roll(l: list[int]) -> list[int] {
    (tmp1, tmp2) = (l[:-1], l[-1]);
    l[1:] = tmp1;
    l[0] = tmp2;
    return l;
}