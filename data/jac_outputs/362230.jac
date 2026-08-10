"""Obtains an image band id from its path."""
def getBandIdFromBandPath(bandPath: str) -> str {
    return bandPath[-6:-4];
}