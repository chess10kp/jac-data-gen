"""The dataset supplied is scaled with the supplied scale. The scaled
dataset is returned."""
def scale_yaxis(dataset: list[float], scale: dict[str, float | str]) -> dict[str, list[float] | str] {
    result = {};
    result["data"] = [x / scale["scale"] for x in dataset];
    result["format"] = scale["label"];
    return result;
}