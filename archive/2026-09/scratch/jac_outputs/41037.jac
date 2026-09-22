"""Check if list of three sides is a triangle."""
def isTriangle(input: list[float]) -> bool {
    return 2 * max(input) < sum(input);
}