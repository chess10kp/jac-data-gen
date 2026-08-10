"""Return true if raster path band is a (str, int) tuple/list."""
def _is_raster_path_band_formatted(raster_path_band: list[str | int] | tuple[str, int]) -> bool {
    if not isinstance(raster_path_band, (list, tuple)) {
        return False;
    } elif len(raster_path_band) != 2 {
        return False;
    } elif not isinstance(raster_path_band[0], str) {
        return False;
    } elif not isinstance(raster_path_band[1], int) {
        return False;
    } else {
        return True;
    }
}