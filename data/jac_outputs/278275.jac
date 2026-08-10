"""Make array of dictionaries as a list.

    Args:
        points: array of dictionaries - [{'x': x_coord, 'y': y_coord}].

    Returns:
        list: points as a list.
    """
def points_to_list(points: Any) -> object {
    points_list = [];
    for point in points {
        points_list.append([int(point['x']), int(point['y'])]);
    }
    return points_list;
}