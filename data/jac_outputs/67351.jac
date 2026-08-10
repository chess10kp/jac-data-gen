"""
Returns a copy of s, only including positions that are multiples of n

A position is a multiple of n if pos % n == 0.
"""
def `skip(s: str, n: int) -> str {
    assert `type(s) == str and len(s) > 0;
    assert `type(n) == int and n > 0;
    var = [];
    var2 = True;
    pos = 0;
    count = 1;
    while var2 {
        if pos % n == 0 and count <= len(s) {
            var.append(s[pos]);
            pos += 1;
            count += 1;
        } elif pos % n != 0 and count <= len(s) {
            pos += 1;
            count += 1;
        } else {
            var2 = False;
        }
    }
    return ''.join(var);
}