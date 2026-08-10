"""If the well is a melanophore, kill it."""
def death_m(well: str) -> str {
    if well == 'M' {
        return 'S';
    }
    return well;
}