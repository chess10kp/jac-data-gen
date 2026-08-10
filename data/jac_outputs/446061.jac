import re;

"""Find all indices of patterns in a string."""
def find_str(string: str, pattern: str) -> list[int] {
    if not pattern.isalpha() {
        pattern = "\\" + pattern;
    }
    return [m.start() for m in re.finditer(pattern, string)];
}