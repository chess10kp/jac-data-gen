"""http://en.wikipedia.org/wiki/Luhn_algorithm ."""
def luhn_checksum(check_number: int | str) -> int {
    def digits_of(n: int | str) -> list[int] {
        return [int(d) for d in str(n)];
    }
    digits = digits_of(check_number);
    odd_digits = digits[-1::-2];
    even_digits = digits[-2::-2];
    checksum = 0;
    checksum += sum(odd_digits);
    for d in even_digits {
        checksum += sum(digits_of(d * 2));
    }
    return checksum % 10;
}