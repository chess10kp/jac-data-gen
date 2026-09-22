"""Old-style dead zone scaling, required for similar drive behaviour."""
def dead_zone(controller_input: float, dead_zone: float) -> float {
    if controller_input <= dead_zone and controller_input >= -dead_zone {
        return 0;
    } elif controller_input > 0 {
        return (controller_input - dead_zone) / (1 - dead_zone);
    } else {
        return (-controller_input - dead_zone) / (dead_zone - 1);
    }
}