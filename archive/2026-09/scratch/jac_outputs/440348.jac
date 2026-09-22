"""Generates the binary format n dtype defualts to double"""
def getfmt(n: int, dtype: str = "d") -> str {
    fmt = dtype;
    for _ in range(n) {
        fmt += dtype;
    }
    return fmt;
}