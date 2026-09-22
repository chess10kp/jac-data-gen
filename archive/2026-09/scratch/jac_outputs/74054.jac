"""
    Gets the object points and image points of a requested set of files.
    """
def get_matching_points(
    requested_file_names: list[str],
    all_file_names: list[str],
    object_points: list[list[float]],
    image_points: list[list[float]]
) -> tuple[list[list[float]], list[list[float]]] {
    requested_file_nameset = set(requested_file_names);
    requested_object_points = [];
    requested_image_points = [];
    for (index, filename) in enumerate(all_file_names) {
        if filename in requested_file_nameset {
            requested_object_points.append(object_points[index]);
            requested_image_points.append(image_points[index]);
        }
    }
    return (requested_object_points, requested_image_points);
}