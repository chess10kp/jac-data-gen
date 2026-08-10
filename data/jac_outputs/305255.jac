"""Convert row index in response data matrix into 3D coordinate in
(original) ROI volume.
"""
def idx2coord(vec_idx: int) -> tuple[float, float, float] {
    data_size = (18, 64, 64);
    coord_z = vec_idx % data_size[2];
    coord_x = vec_idx / (data_size[1] * data_size[2]);
    coord_y = (vec_idx % (data_size[1] * data_size[2])) / data_size[2];
    return (coord_x, coord_y, coord_z);
}