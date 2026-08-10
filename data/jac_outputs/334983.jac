"""When number of lines > 2*N, reduce to N."""
def limit_lines(lines: list[bytes], N: int = 32) -> list[bytes] {
    if len(lines) > 2 * N {
        lines = [b'... showing only last few lines ...'] + lines[-N:];
    }
    return lines;
}