"""Split a string"""
def parse_regions(region_str: Any) -> object {
    if (region_str is None) {
        return [];
    }
    return region_str.split(',');
}