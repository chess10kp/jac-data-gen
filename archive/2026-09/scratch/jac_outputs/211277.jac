"""Earth Engine band names"""
def ee_bands_rgb(collection: str) -> list[str] {
    dic = {
        'Sentinel2': ['B4', 'B3', 'B2'],
        'Landsat7': ['B3', 'B2', 'B1'],
        'CroplandDataLayers': ['cropland']
    };
    return dic[collection];
}