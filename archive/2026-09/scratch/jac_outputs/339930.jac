"""Parse version from changelog written in RST format."""
def get_version(data: str) -> str {
    def all_same(s: str) -> bool {
        for x in s {
            if x != s[0] {
                return False;
            }
        }
        return True;
    }
    def has_digit(s: str) -> bool {
        for char in s {
            if char.isdigit() {
                return True;
            }
        }
        return False;
    }
    lines = data.splitlines();
    candidates = [
        v
        for (v, u) in zip(lines, lines[1:])
        if len(v) == len(u) and all_same(u) and has_digit(v) and "." in v
    ];
    return next(iter(candidates));
}