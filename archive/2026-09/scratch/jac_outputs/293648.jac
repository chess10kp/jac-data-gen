"""
    Function that returns the N number of most at risk stations.
    Args:
        stations (list): List of stations (MonitoringStation).
        N (int): Length of the desired list
    Returns:
        list: List of stations (MonitoringStation).
    """
def stations_highest_rel_level(stations: Any, N: Any) -> object {
    return sorted(
        filter(lambda (x: Any) { (x.relative_water_level() is not None); }, stations),
        key=lambda (x: Any) { x.relative_water_level(); },
        reverse=True
    )[:N];
}