"""
Swap key and value and return
"""
def swap_parts(line: tuple[str | int, str | int]) -> tuple[str | int, str | int] {
    return (line[1], line[0]);
}