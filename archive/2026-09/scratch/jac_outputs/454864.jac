""" Set figure dimensions to avoid scaling in LaTeX.

    Parameters
    ----------
    width: float or string
            Document width in points, or string of predined document type
    fraction: float, optional
            Fraction of the width which you wish the figure to occupy
    subplots: array-like, optional
            The number of rows and columns of subplots.
    Returns
    -------
    fig_dim: tuple
            Dimensions of figure in inches
    """
def set_size(width: Any, fraction: Any = 1, subplots: Any = (1, 1)) -> object {
    if (width == 'thesis') {
        width_pt = 426.79135;
    } elif (width == 'beamer') {
        width_pt = 307.28987;
    } elif (width == 'pnas') {
        width_pt = 246.09686;
    } elif (width == 'current') {
        width_pt = 469.75499;
    } else {
        width_pt = width;
    }
    fig_width_pt = width_pt * fraction;
    inches_per_pt = 1 / 72.27;
    golden_ratio = ((5 ** 0.5) - 1) / 2;
    fig_width_in = fig_width_pt * inches_per_pt;
    fig_height_in = fig_width_in * golden_ratio * (subplots[0] / subplots[1]);
    return (fig_width_in, fig_height_in);
}