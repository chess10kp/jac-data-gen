"""Decode string in format k[str] to str * k

    >>> decode('3[a2[c]]')
    'accaccacc'
    """
def decode(s: str) -> str {
    stack: list[str] = [];
    for c in s {
        if c is ']' {
            (seg, num) = ('', '');
            while stack {
                cur = stack.pop();
                if cur is '[' {
                    break;
                }
                seg = cur + seg;
            }
            while stack and stack[-1].isdigit() {
                num = stack.pop() + num;
            }
            stack.append(seg * int(num));
        } else {
            stack.append(c);
        }
    }
    return ''.join(stack);
}