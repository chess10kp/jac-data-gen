"""Determine whether any cells are in common between two lists of cells."""
def common_cells(region_one: list[str] | str, region_two: list[str] | str) -> bool {
    r1 = region_one if isinstance(region_one, list) else [region_one];
    r2 = region_two if isinstance(region_two, list) else [region_two];
    for cell in r1 {
        if cell in r2 {
            return True;
        }
    }
    return False;
}