"""coordinate formatter replacement"""
def format_coord(x: Any, y: Any) -> object {
    return 'x={x}, y={y:.2f}'.format(x=x, y=y);
}