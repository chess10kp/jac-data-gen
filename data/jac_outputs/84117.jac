"""Get address range of code."""
def address_range(prg: list[int]) -> bytearray {
    result = bytearray();
    result_end = prg[1] * 255 + prg[0] + len(prg) - 2;
    result.append(int(result_end / 255));
    result.append(int(result_end % 255));
    result.append(prg[1]);
    result.append(prg[0]);
    return result;
}