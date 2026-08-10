"""Maps route list, which includes job ids to route location list."""
def map_route_to_route_locations(
    vehicle_location: int, route: list[int], jobs: dict[int, list[int]]
) -> list[int] {
    return [vehicle_location] + [jobs[job][0] for job in route];
}