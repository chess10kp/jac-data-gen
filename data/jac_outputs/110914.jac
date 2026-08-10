def reverse(string: str) -> str {
    if len(string) < 2 {
        return string;
    }
    return reverse(string[1:]) + string[0];
}