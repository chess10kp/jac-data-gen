"""Check if a point is inside a rectangle."""
def rectContains(rect: tuple[int, int, int, int], point: tuple[int, int]) -> bool {
    if point[0] < rect[0] {
        return False;
    } elif point[1] < rect[1] {
        return False;
    } elif point[0] > rect[0] + rect[2] {
        return False;
    } elif point[1] > rect[1] + rect[3] {
        return False;
    }
    return True;
}