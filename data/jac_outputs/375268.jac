"""
    Returns a sql fragment that sums the length of OSM line features per grid
    cell by category

    Args:
        grid (string): a PostGIS table name containing the grid
        osm (string): a PostGIS table name containing the OSM line features
        cat (string): a PostGIS table containing the OSM line features'
            categories

    Returns:
        sql (string): an sql fragment
    """
def osm_length_sql(grid: str, osm: str, cat: str) -> str {
    sql = "SELECT "
    "SUM(CASE WHEN cat.cat = 1 "
    "THEN ST_Length(ST_Intersection(grid.cell, osm.way)) "
    "ELSE 0 END) AS lineCult, "
    "SUM(CASE WHEN cat.cat = 2 "
    "THEN ST_Length(ST_Intersection(grid.cell, osm.way)) "
    "ELSE 0 END) AS lineIndus, "
    "SUM(CASE WHEN cat.cat = 3 "
    "THEN ST_Length(ST_Intersection(grid.cell, osm.way)) "
    "ELSE 0 END) AS lineNat, "
    "SUM(CASE WHEN cat.cat = 4 "
    "THEN ST_Length(ST_Intersection(grid.cell, osm.way)) "
    "ELSE 0 END) AS lineStruct, "
    "SUM(CASE WHEN cat.cat = 0 "
    "THEN ST_Length(ST_Intersection(grid.cell, osm.way)) "
    "ELSE 0 END) AS lineMisc, grid.id AS id "
    "FROM %s AS grid, "
    "%s AS osm, "
    "%s AS cat "
    "WHERE cat.osm_id = osm.osm_id AND ST_Intersects(grid.cell, osm.way)"
    " GROUP BY id";
    return sql % (grid, osm, cat);
}