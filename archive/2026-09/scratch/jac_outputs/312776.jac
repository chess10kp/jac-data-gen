"""Determine year tick positions for a graph axis from a list of years."""
def __get_years_tickvals(years: list[int]) -> list[int] {
    min_year = int(min(years));
    max_year = int(max(years));
    delta = max_year - min_year;
    if delta >= 80 {
        stepsize = 10;
    } elif delta >= 40 {
        stepsize = 5;
    } elif delta >= 16 {
        stepsize = 2;
    } else {
        stepsize = 1;
    }
    return list(range(min_year, max_year + stepsize, stepsize));
}