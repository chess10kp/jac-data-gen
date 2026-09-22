"""Varify if given number is a valid ISBN 10 number"""
def is_valid(isbn: str) -> bool {
    digits = [int(n) for n in isbn if n.isnumeric()];
    if len(digits) == 9 and isbn[-1].upper() == "X" {
        digits.append(10);
    }
    if len(digits) != 10 {
        return False;
    }
    sum_ = sum((len(digits) - i) * v for (i, v) in enumerate(digits));
    return sum_ % 11 == 0;
}