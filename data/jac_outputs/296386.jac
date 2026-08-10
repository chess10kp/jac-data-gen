"""
    OO  OO   OOO
        OOO  OOO
             OOOO
    Number of Os:
    2   4    7"""
def vis8(n: int) -> str {
    result = '';
    for i in range(1, n + 1) {
        result += 'O' * n;
        if i == n {
            result += 'O\n';
        } else {
            result += '\n';
        }
    }
    return result;
}