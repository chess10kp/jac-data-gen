"""
    Visualization parameters
    """
def vizz_params_rgb(collection: Any) -> object {
    dic = {
        'Sentinel2_TOA': {'min': 0, 'max': 3000, 'bands': ['B4', 'B3', 'B2']},
        'Landsat7_SR': {
            'min': 0,
            'max': 3000,
            'gamma': 1.4,
            'bands': ['B3', 'B2', 'B1']
        },
        'Landsat8_SR': {
            'min': 0,
            'max': 3000,
            'gamma': 1.4,
            'bands': ['B4', 'B3', 'B2']
        },
        'CroplandDataLayers': {'min': 0, 'max': 3, 'bands': ['landcover']},
        'NationalLandCoverDatabase': {'min': 0, 'max': 1, 'bands': ['impervious']}
    };
    return dic[collection];
}