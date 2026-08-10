"""Trim dictionary representation of feature from featureXML output."""
def createFeature(element: dict[str, str | int | float | list[dict[str, str | int | float]]]) -> dict[str, str | int | float] {
    feature = {};
    keys = [
        "FWHM",
        "charge",
        "intensity",
        "overallquality",
        "label",
        "spectrum_index",
        "spectrum_native_id"
    ];
    newkeys = [
        "FWHM",
        "Charge",
        "Intensity",
        "Overallquality",
        "Label",
        "spectrum_index",
        "spectrum_native_id"
    ];
    for (key, newkey) in zip(keys, newkeys) {
        feature[newkey] = element[key];
    }
    feature["RT"] = element["position"][0]["position"];
    feature["mz"] = element["position"][1]["position"];
    hull_x = [point["x"] for point in element["convexhull"][0]["pt"]];
    feature["RTmin"] = min(hull_x);
    feature["RTmax"] = max(hull_x);
    return feature;
}