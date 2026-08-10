"""
Gets sorted start attributes list.
"""
def get_sorted_start_activities_list(start_activities: dict[str, int]) -> list[list[str | int]] {
    listact = [[sa, start_activities[sa]] for sa in start_activities];
    return sorted(listact, key=lambda (x: list[str | int]) { x[1] }, reverse=True);
}