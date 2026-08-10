"""Parse the args the same way plt.plot does."""
def parse_plot_args(*args: float | list[float] | str, **options: int | float | str | bool) -> tuple[float | list[float] | str | None, float | list[float] | str | None, str | None] {
    x: float | list[float] | str | None = None;
    y: float | list[float] | str | None = None;
    style: str | None = None;
    match len(args) {
        case 1:
            y = args[0];
        case 2:
            if isinstance(args[1], str) {
                (y, style) = args;
            } else {
                (x, y) = args;
            }
        case 3:
            (x, y, style) = args;
        case _:
            ;
    }
    return (x, y, style);
}