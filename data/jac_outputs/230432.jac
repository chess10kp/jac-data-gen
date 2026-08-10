"""Convert binary string to hexadecimal string.
For instance: '11010' -> '1a'"""
def bin2hex(x: str) -> str {
    hex(int(x, 2))[2:]
}