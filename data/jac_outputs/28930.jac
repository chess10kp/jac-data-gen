"""Find most affected area and the number of hurricanes it was involved in."""
def most_affected_area(affected_areas_count: dict[str, int]) -> tuple[str, int] {
    max_area = 'Central America';
    max_area_count = 0;
    for area in affected_areas_count {
        if affected_areas_count[area] > max_area_count {
            max_area = area;
            max_area_count = affected_areas_count[area];
        }
    }
    return (max_area, max_area_count);
}