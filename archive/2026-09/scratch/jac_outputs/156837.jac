"""Lookup collection and suffix based on the GEE collection name."""
def get_collection_and_suffix(collection_name: str) -> tuple[str, str] {
    match collection_name {
        case 'COPERNICUS/S2':
            collection = 'Sentinel2';
            satellite_suffix = 'S2';
        case 'LANDSAT8':
            collection = 'Landsat8';
            satellite_suffix = 'L8';
        case 'LANDSAT7':
            collection = 'Landsat7';
            satellite_suffix = 'L7';
        case 'LANDSAT5':
            collection = 'Landsat5';
            satellite_suffix = 'L5';
        case 'LANDSAT4':
            collection = 'Landsat4';
            satellite_suffix = 'L4';
        case _:
            raise RuntimeError("Unknown collection_name {}".format(collection_name));
    }
    return (collection, satellite_suffix);
}