"""float array to #rrggbb"""
def formatColorfa(a: list[float]) -> str {
    return '#%02x%02x%02x' % (
        int(round(a[0] * 255)),
        int(round(a[1] * 255)),
        int(round(a[2] * 255))
    );
}