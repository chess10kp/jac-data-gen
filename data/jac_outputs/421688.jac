"""Find furthest room from the distances grid."""
def find_furthest_room(distances: list[list[int]]) -> int {
    max(max(row) for row in distances)
}