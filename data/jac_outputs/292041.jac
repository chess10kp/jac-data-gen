"""
    Convert device_coordinate according to the tensor map.

    Args:
        device_coordinate (list): The coordinate for local device in the device matrix.
        tensor_map (list): The map relation between tensor and devices.

    Returns:
        List, the converted coordinate.
    """
def _convert_to_new_device_coordinate(
    device_coordinate: list[int],
    tensor_map: list[int]
) -> list[int] {
    device_coordinate_new = [];
    for i in range(len(tensor_map)) {
        if tensor_map[len(tensor_map) - 1 - i] != -1 {
            device_coordinate_new.insert(
                0,
                device_coordinate[
                    len(device_coordinate) - 1 - tensor_map[len(tensor_map) - 1 - i]
                ]
            );
        } else {
            device_coordinate_new.insert(0, 0);
        }
    }
    return device_coordinate_new;
}