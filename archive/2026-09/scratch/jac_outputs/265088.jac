"""How many individual line segments are in these paths?"""
def num_segments(paths: Any) -> object {
    return sum((len(p) - 1) for p in paths);
}