"""
0 if a's precedence is more than b operator
1 otherwise
"""
def checkOperatorPrecedence(a: str, b: str) -> int {
    check = {
        '(': 3,
        '^': 2,
        '*': 2,
        '/': 2,
        '-': 1,
        '+': 1
    };
    return 1 if check[a] <= check[b] else 0;
}