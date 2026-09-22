"""Transfer the word into a concatenated digit string."""
def string_to_number(s: str) -> str {
    number = '';
    n = 0;
    number += str(n);
    for _ in range(len(s) - 1) {
        n += 1;
        number += str(n);
    }
    return number;
}