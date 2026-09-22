"""Binary voodoo magic."""
def binary_add(first: int, second: int) -> int {
    if second == 0 {
        return first;
    } elif first == 0 {
        return second;
    }
    xor = first ^ second;
    carry = (first & second) << 1;
    return binary_add(xor, carry);
}