"""Expand features to include pairs of features
    where one is always a f=v feature."""
def feature_pairs(f: list[str]) -> list[str] {
    pairs = [x + ".x." + y for x in f for y in f if '=' in y];
    return pairs + f;
}