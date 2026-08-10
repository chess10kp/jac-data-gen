"""Multiplies x or y data by their corresponding factor."""
def data_transformer(
    x: float, y: float, xfactor: float, yfactor: float, **kwargs: str
) -> dict[str, float] {
    {"x": x * xfactor, "y": y * yfactor}
}