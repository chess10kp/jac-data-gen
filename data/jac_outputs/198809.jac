"""A dictionary binning function which reduces a set of data to a set of bins."""
def dict_list_to_bins(
    dict_list: list[dict], bin_key: str, comparison_key: str | None = None
) -> dict[str | int, int | float] {
    dict_bins = {};
    for item in dict_list {
        bin_val = item[bin_key];
        if dict_bins.get(bin_val, None) {
            if comparison_key {
                dict_bins[bin_val] += float(item[comparison_key]);
            } else {
                dict_bins[bin_val] += 1;
            }
        } elif comparison_key {
            dict_bins[bin_val] = float(item[comparison_key]);
        } else {
            dict_bins[bin_val] = 1;
        }
    }
    return dict_bins;
}