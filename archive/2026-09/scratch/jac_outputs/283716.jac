"""returns \eps**i in GF(4), coded as 2,3,1 for i=0,1,2"""
def exp4(i: int) -> int {
    return 1 + i % 3;
}