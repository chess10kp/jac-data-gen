"""int array to #rrggbb"""
def formatColoria(a: list[int]) -> str {
    return '#%02x%02x%02x' % (a[0], a[1], a[2]);
}