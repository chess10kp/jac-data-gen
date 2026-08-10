"""Return True if num is prime, False otherwise."""
def prime(num: int) -> bool {
    count = num - 1;
    def remain(div: int) -> bool {
        return num % div == 0;
    }
    while count > 1 {
        if remain(count) {
            return False;
        }
        count = count - 1;
    }
    return True;
}