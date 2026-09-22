"""Return true if n has two eights in a row."""
def double_eights(n: int) -> bool {
    temp = 0;
    count = 0;
    while n > 0 {
        temp = n % 10;
        n //= 10;
        if temp == 8 {
            count += 1;
        } else {
            count = 0;
        }
        if count == 2 {
            return True;
        }
    }
    return False;
}