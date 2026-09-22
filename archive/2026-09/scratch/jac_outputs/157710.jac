"""Constructs an opinions dictionary for a repiet compiler pass
    (implicity filling in defaults)"""
def default_opinions(
    codel_size: int = 1,
    noncoding: str = 'block',
    sliding: str = 'halting',
    color_dir_h: str = '-',
    color_dir_l: str = '-'
) -> dict[str, int | str] {
    return dict(
        codel_size=codel_size,
        noncoding=noncoding,
        sliding=sliding,
        color_dir_h=color_dir_h,
        color_dir_l=color_dir_l
    );
}