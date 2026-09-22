"""returns geojson box around lat and lng"""
def return_geojson(lat: Any, lng: Any, increment: Any) -> object {
    geojson_geometry = {
        "type": "Polygon",
        "coordinates": [
            [
                [(lng + increment), (lat + increment)],
                [(lng + increment), (lat - increment)],
                [(lng - increment), (lat - increment)],
                [(lng - increment), (lat + increment)],
                [(lng + increment), (lat + increment)]
            ]
        ]
    };
    return geojson_geometry;
}