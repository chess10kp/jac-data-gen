"""Convert the command-line arguments from real (um) units to pixels."""
def calculate_parameters_in_pixels(
    x_pixel_um: float,
    y_pixel_um: float,
    z_pixel_um: float,
    soma_diameter_um: float,
    max_cluster_size_um3: float,
    ball_xy_size_um: float,
    ball_z_size_um: float
) -> tuple[int, int, int, int] {
    mean_in_plane_pixel_size = 0.5 * (x_pixel_um + y_pixel_um);
    voxel_volume = x_pixel_um * y_pixel_um * z_pixel_um;
    soma_diameter = int(round(soma_diameter_um / mean_in_plane_pixel_size));
    max_cluster_size = int(round(max_cluster_size_um3 / voxel_volume));
    ball_xy_size = int(round(ball_xy_size_um / mean_in_plane_pixel_size));
    ball_z_size = int(round(ball_z_size_um / z_pixel_um));
    return (soma_diameter, max_cluster_size, ball_xy_size, ball_z_size);
}