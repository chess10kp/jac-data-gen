"""Return a list of all pedestrian observation combinations (in list format) for a vehicle under the 4 location scheme"""
def all_ped_combos_lsts(num_locs: int = 4, val_set: tuple[str, ...] = ("0", "1")) -> list[list[str]] {
    res: list[list[str]] = [];
    if num_locs == 0 {
        return [];
    }
    if num_locs == 1 {
        return [[flag] for flag in val_set];
    }
    for comb in all_ped_combos_lsts(num_locs - 1, val_set) {
        for flag in val_set {
            appended = comb + [flag];
            res.append(appended);
        }
    }
    return res;
}