"""Check whether ticket brackets match the given patterns."""
def check_ticket(ticket: str, patterns: dict[str, str]) -> bool {
    stack: list[str] = [];
    for c in ticket {
        if c in patterns {
            if len(stack) == 0 {
                return False;
            }
            if stack.pop() != patterns[c] {
                return False;
            }
        } else {
            stack.append(c);
        }
    }
    return len(stack) == 0;
}