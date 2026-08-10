"""Given a vertex id and partial isomorphisms phi, return the inverse transformed vertex id."""
def inv_transform_vertex(x: int, phi: set[tuple[int, int]]) -> int {
    for _phi in phi {
        if _phi[1] == x {
            return _phi[0];
        }
    }
    raise Exception('Could not find inverse transformation');
}