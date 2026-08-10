"""
	Retrieves the specified raster bands from the supplied dataset
	"""
def getRasterBands(dataset: Any, bandIndices: Any) -> object {
    return `list([dataset.GetRasterBand(i) for i in bandIndices]);
}