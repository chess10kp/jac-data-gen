"""Return manhattan distance between a and b"""
def manhat_dist(a: Any, b: Any) -> object {
    return (abs((a[0] - b[0])) + abs((a[1] - b[1])) + abs((a[2] - b[2])));
}