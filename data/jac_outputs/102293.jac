"""Calculate the centroid from a vectorset X"""
def centroid(X: list[int]) -> float {
    return sum(X) / len(X);
}