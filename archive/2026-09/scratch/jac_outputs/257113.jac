"""Converts a zookeeper path with a counter into an integer of that counter."""
def counter_value(path: str) -> int {
    return int(path[-10:]);
}