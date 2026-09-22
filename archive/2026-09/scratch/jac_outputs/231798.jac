"""
Arguments:
    faces ([[vIdx, ...], ...]): A face representation

Returns:
    set : A set of vertex indexes along the border of the mesh
"""
def getBorders(faces: list[list[int]]) -> set[int] {
    edge_pairs = set();
    for face in faces {
        for f in range(len(face)) {
            edge_pairs.add((face[f], face[f - 1]));
        }
    }
    borders = set();
    for ep in edge_pairs {
        if (ep[1], ep[0]) not in edge_pairs {
            borders.update(ep);
        }
    }
    return borders;
}