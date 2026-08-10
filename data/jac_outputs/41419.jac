"""Create a samtools-style region string such as chrN:start-end."""
def createRegionStr(chr: str | int, start: int | str, end: int | str | None = None) -> str {
    end_val = end if end is not None else start;
    return str(chr) + ":" + str(int(start)) + "-" + str(int(end_val));
}