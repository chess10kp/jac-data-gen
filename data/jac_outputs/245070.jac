"""Return decoded string, given encoded string 's'."""
def decodeString(s: str) -> str {
    """Decode scope at index i with repeat count; return next index and decoded chars."""
    def decodeScope(i: int = 0, repeat: int = 1) -> tuple[int, list[str]] {
        decoded: list[str] = [];
        while i < len(s) {
            if s[i].isdigit() {
                next_repeat = 0;
                while s[i] != '[' {
                    next_repeat *= 10;
                    next_repeat += int(s[i]);
                    i += 1;
                }
                (i, inner_decoded) = decodeScope(i + 1, next_repeat);
                decoded += inner_decoded;
            } elif s[i] == ']' {
                i += 1;
                break;
            } else {
                decoded.append(s[i]);
                i += 1;
            }
        }
        return (i, decoded * repeat);
    }
    (_, decoded) = decodeScope();
    return ''.join(decoded);
}