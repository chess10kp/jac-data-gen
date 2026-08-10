"""BizzFuzz template tag."""
def bizz_fuzz(num: int) -> str | int {
    output = '';
    if num % 3 == 0 {
        output += 'Bizz';
    }
    if num % 5 == 0 {
        output += 'Fuzz';
    }
    return output or num;
}