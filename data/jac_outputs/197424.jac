"""Convert hexadecimal string to decimal integer."""
def hex2dec(inp: str, verbose: bool = True) -> int {
    out = 0;
    n = len(inp);
    for i in range(n)[::-1] {
        try {
            ch = str(inp[i].upper());
        } except Exception {
            ch = str(inp[i]);
        }
        digit: int;
        if ch == 'A' { digit = 10; }
        elif ch == 'B' { digit = 11; }
        elif ch == 'C' { digit = 12; }
        elif ch == 'D' { digit = 13; }
        elif ch == 'E' { digit = 14; }
        elif ch == 'F' { digit = 15; }
        elif ch != int(ch) {
            print('Invalid character **', ch, '**');
            return 0;
        } else {
            digit = int(ch);
        }
        out = out + digit * (16 ** (n - 1 - i));
    }
    if verbose { print(out); }
    return out;
}