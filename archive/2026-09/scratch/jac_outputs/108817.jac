"""Set rcParam of matplotlib."""
def set_rcParams(font_size: Any = 10, line_width: Any = 1) -> object {
    parameters = {
        "text.usetex": True,
        "font.family": "serif",
        "axes.labelsize": font_size,
        "font.size": font_size,
        "legend.fontsize": font_size,
        "xtick.major.width": 0.5,
        "xtick.labelsize": (font_size - 2),
        "ytick.major.width": 0.5,
        "ytick.labelsize": (font_size - 2),
        "lines.linewidth": line_width,
        "axes.linewidth": 0.5,
        "grid.linewidth": 0.25
    };
    return parameters;
}