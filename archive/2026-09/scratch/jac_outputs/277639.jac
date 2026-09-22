"""
Returns an list with unique routes for all nodes.
This function achieves this by removing simetrical routes (A, B, C) == (C, B, A).
"""
def unique_routes(routes: list[list[str]]) -> list[list[str]] {
    for route in list(reversed(routes)) {
        if list(reversed(route)) in routes {
            routes.remove(route);
        }
    }
    return routes;
}