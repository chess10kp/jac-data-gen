"""Return a URL for a tile given some OSM tile co-ordinates."""
def get_tile_url(xtile: int, ytile: int, zoom: int) -> str {
    return "http://tile.openstreetmap.org/%d/%d/%d.png" % (zoom, xtile, ytile);
}