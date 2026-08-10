"""If the well is melanophore and neighbor is xantophore, kill the melanophore"""
def short_kill_x(well: str, neighbor: str) -> str {
    if well == 'M' and neighbor == 'X' {
        return 'S';
    }
    return well;
}