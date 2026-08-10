"""
    Use a stack to keep track of the brackets, yo!
    Runtime: O(n)
    """
def bb(s: str) -> bool {
    brackets = [];
    matching = {")": "(", "]": "[", "}": "{"};
    for p in s {
        if p in matching.values() {
            brackets.append(p);
        } else {
            try {
                top = brackets[-1];
                if top == matching[p] {
                    brackets.pop();
                }
            } except Exception {
                return False;
            }
        }
    }
    return not brackets;
}