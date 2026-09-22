"""utility for compare dot separate versions. Fills with zeros to proper number comparison"""
def versiontuple(v: str) -> tuple[str, ...] {
    filled = [];
    for point in v.split(".") {
        filled.append(point.zfill(8));
    }
    return tuple(filled);
}