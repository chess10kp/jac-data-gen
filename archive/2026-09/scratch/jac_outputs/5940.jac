"""ip to number """
def i2n(i: str) -> int {
    ip = [int(x) for x in i.split('.')];
    return ip[0] << 24 | ip[1] << 16 | ip[2] << 8 | ip[3];
}