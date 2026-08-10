"""Generate an interpolation pixel scale tag, to customize phase names based on the resolution of the interpolation \
    grid that deflection angles are computed on before interpolating to the and sub aa.

    This changes the phase name 'phase_name' as follows:

    pixel_scale_interpolation_grid = 1 -> phase_name
    pixel_scale_interpolation_grid = 2 -> phase_name_pixel_scale_interpolation_grid_2
    pixel_scale_interpolation_grid = 2 -> phase_name_pixel_scale_interpolation_grid_2
    """
def pixel_scale_interpolation_grid_tag_from_pixel_scale_interpolation_grid(
    pixel_scale_interpolation_grid: float | None
) -> str {
    if pixel_scale_interpolation_grid is None {
        return "";
    } else {
        return "__interp_{0:.3f}".format(pixel_scale_interpolation_grid);
    }
}