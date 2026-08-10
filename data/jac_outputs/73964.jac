"""
    Set figure dimensions to avoid scaling in LaTeX.
    """
def set_size(width: float, fraction: int = 1, subplots: tuple[int, int] = (1, 1)) -> tuple[float, float] {
    golden_ratio = 1.618;
    height = width / golden_ratio * (subplots[0] / subplots[1]);
    return (width, height);
}