import from math { ceil, floor }

"""Get axis limit."""
def get_ax_lim(ax_min: float, ax_max: float, base: int = 10) -> tuple[float, float] {
    ax_min = floor(ax_min * base) / base;
    ax_max = ceil(ax_max * base) / base;
    return (ax_min, ax_max);
}