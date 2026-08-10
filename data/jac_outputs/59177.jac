"""Convert textbox corner coordinate from str to float"""
def get_corner_coord(vhpos: str | None) -> float {
    if vhpos is None or vhpos == 'right' or vhpos == 'top' {
        return 0.9;
    }
    return 0.1;
}