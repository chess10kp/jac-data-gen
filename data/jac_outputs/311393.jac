def replace_range(old_lines: list[int], new_lines: list[int], r: tuple[int, int] | None = None) -> list[int] {
    (start, end) = r or (0, len(old_lines));
    assert 0 <= start <= end <= len(old_lines);
    return old_lines[:start] + new_lines + old_lines[end:];
}