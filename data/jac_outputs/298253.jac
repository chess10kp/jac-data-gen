"""If a string already exists in a list, add a number to it."""
def handle_same_string(str1: str, alist: list[str]) -> str | None {
    if str1 in alist {
        for i in range(1, 1000) {
            candidate = str1 + (' (%i)' % i);
            if candidate not in alist {
                return candidate;
            }
        }
    } else {
        return str1;
    }
}