"""
Return the geometry of a feature

params:
    feature -> a feature
"""
def getFeatureGeometry(feature: dict[str, dict[str, object]]) -> dict[str, object] {
    return feature["geometry"];
}