"""Generate the region_params list in the tiling parameter dict"""
def generate_region_info(region_params: dict[str, list[int | float]]) -> list[dict[str, int | float]] {
    return [
        {rp: region_params[rp][i] for rp in region_params}
        for i in range(len(region_params['region_start_x']))
    ];
}