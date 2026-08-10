"""
    Convert OSM zoom level to pixels per meter on Equator. See
    https://wiki.openstreetmap.org/wiki/Zoom_levels
    """
def osm_zoom_level_to_pixels_per_meter(
    zoom_level: float, equator_length: float
) -> float {
    return 2.0 ** zoom_level / equator_length * 256.0;
}