"""Convert a 4d shape that we get from TPU estimator to a 3d shape."""
def physical_shape_3d_from_topology_proto_4d(mesh_shape: list[int]) -> list[int] {
    if len(mesh_shape) != 4 or mesh_shape[2] != 1 {
        raise ValueError("Expected a 4d shape [x, y, 1, core]");
    }
    return [mesh_shape[1], mesh_shape[0], mesh_shape[3]];
}