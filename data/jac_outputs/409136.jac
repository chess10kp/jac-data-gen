""" convert EPSG code to OGC URN CRS ``urn:ogc:def:crs:epsg::<code>``
    notation """
def asURN(epsg: int | str) -> str {
    return "urn:ogc:def:crs:epsg::%d" % int(epsg);
}