"""Get image ranges for a list of experiments (including scanless exp.)"""
def get_image_ranges(experiments: list) -> list[tuple[int, int]] {
    return [
        e.sequence.get_image_range() if e.sequence else (0, 0) for e in experiments
    ] as list[tuple[int, int]];
}