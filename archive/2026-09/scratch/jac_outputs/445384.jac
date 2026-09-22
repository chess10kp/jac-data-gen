"""Return list of dimension ints"""
def box_lengths(dimensions: str) -> list[int] {
    sorted([int(i) for i in dimensions.split('x')])
}