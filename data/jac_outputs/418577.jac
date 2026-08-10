"""Find UTM zone for lon and lat values."""
def findUTMZone(lon: float, lat: float) -> str {
    zone = int((int(lon) + 180) / 6) + 1;
    return str(zone) + 'N' if lat > 0 else str(zone) + 'S';
}