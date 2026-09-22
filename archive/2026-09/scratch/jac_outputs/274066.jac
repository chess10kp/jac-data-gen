"""
    Get polygon in GML format given GeoJSON
    """
def get_gml(geo_json: dict[str, list[list[list[float]]]]) -> str {
    gml = "<gml:Polygon srsName=\"http://www.opengis.net/gml/srs/epsg.xml#4326\" "
    "xmlns:gml=\"http://www.opengis.net/gml\">\n  "
    " <gml:outerBoundaryIs>\n      <gml:LinearRing>\n         <gml:coordinates>";
    coordinates = geo_json["coordinates"][0];
    for point in coordinates {
        gml = gml + str(point[1]) + "," + str(point[0]) + " ";
    }
    gml = (
        gml[:-1]
        + "</gml:coordinates>\n      </gml:LinearRing>\n   </gml:outerBoundaryIs>\n</gml:Polygon>"
    );
    return gml;
}