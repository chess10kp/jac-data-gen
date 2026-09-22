""" given a line size, piece and space size
      return number of pieces that will fit it and
      0-based starting position as a tuple"""
def linesin(line: int, piece: int, space: int) -> tuple[int, int] {
    total = line + space;
    unit = piece + space;
    pieces = total // unit;
    rem = total % unit;
    if pieces == 0 {
        return (0, 0);
    }
    if rem == 0 {
        return (pieces, rem);
    }
    return (pieces, rem // 2);
}