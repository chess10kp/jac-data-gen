"""
See https://engineering.q42.nl/redis-scan-cursor/

Apply mask from max_cursor and reverse bits order
"""
def convert_scan_cursor(cursor: int, max_cursor: int) -> int {
    n = len(bin(max_cursor)) - 2;
    value = bin(cursor)[2:];
    s = ("{:>0%ss}" % n).format(value);
    return int(s[::-1], base=2);
}