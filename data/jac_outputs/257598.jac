"""
:type s: str
:rtype: str
"""
def minRemoveToMakeValid(s: str) -> str {
    (opens, closes) = ([], []);
    for (i, c) in enumerate(s) {
        if c == '(' {
            opens.append(i);
        } elif c == ')' {
            if len(opens) == 0 {
                closes.append(i);
            } else {
                opens.pop();
            }
        }
    }
    hs = set(opens + closes);
    return ''.join(s[i] for i in range(len(s)) if i not in hs);
}