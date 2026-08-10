"""Converts a dictionary of physical parameters into a dictionary of normalized parameters."""
def paramsDictPhysical2Normalized(
    params: dict[str, float],
    params_range: dict[str, tuple[float, float]]
) -> dict[str, float] {
    params = dict(params);
    for (key, val) in params.items() {
        params[key] = (val - params_range[key][0]) / (params_range[key][1] - params_range[key][0]);
    }
    return params;
}