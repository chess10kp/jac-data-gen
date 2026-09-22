"""Returns local coordinate in a global region"""
def global2local(gobal_coord: int, start: int, end: int, strand: int) -> int {
    if strand == 1 {
        return gobal_coord - start;
    }
    return end - gobal_coord;
}