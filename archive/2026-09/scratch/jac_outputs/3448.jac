"""
    Returns 'rump' of raster file name, to be used as prefix for tile files.
    rasterFileName is <date>_<time>_<sat. ID>_<product type>_<asset type>.tif(f)
    where asset type can be any of ["AnalyticMS","AnalyticMS_SR","Visual","newVisual"]
    The rump is defined as <date>_<time>_<sat. ID>_<product type>
    """
def get_tile_prefix(rasterFileName: Any) -> object {
    return rasterFileName.rsplit("_", 1)[0].rsplit("_AnalyticMS")[0];
}