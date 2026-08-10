"""Generates map"""
def map_gen(size: Any) -> object {
    map_ = [];
    for _ in range(size) {
        map_.append(([" ~"] * size));
    }
    return map_;
}