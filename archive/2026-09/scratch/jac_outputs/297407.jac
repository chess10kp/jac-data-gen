"""
Converts the_geom to a dictionary containing SRID and a list of coordinate points
"""
def geometry_to_list(geometry: str) -> dict {
    coordinates_list = [];
    points = geometry.split(";");
    (srid, coordinates) = (points[0], points[1]);
    srid = srid[5:];
    points = coordinates[11:(len(coordinates) - 1)].split(",");
    for pair in points {
        coordinates_list.append([float(number) for number in pair.split(" ")]);
    }
    return {"srid": int(srid), "coordinates": coordinates_list};
}