"""Generate a {label: color} mapping from labels and available colors."""
def get_kwcolors(labels: list[str], colors: list[str]) -> dict[str, str] {
    nc = len(colors);
    nl = len(labels);
    n_repeats = (nl + nc - 1) // nc;
    colors = list(colors) * n_repeats;
    return {label: color for (label, color) in zip(labels, colors)};
}