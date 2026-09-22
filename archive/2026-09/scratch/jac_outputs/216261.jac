"""Adjust the legend-style."""
def legend(
    *, shadow: bool = False, frameon: bool = True, fancybox: bool = False
) -> dict[str, bool] {
    return {
        "legend.shadow": shadow,
        "legend.frameon": frameon,
        "legend.fancybox": fancybox
    };
}