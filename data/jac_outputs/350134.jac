"""Return the second lowest value in a list of numbers."""
def get_second_smallest(values: list[float]) -> float {
    (smallest, second_smallest) = (float("inf"), float("inf"));
    for value in values {
        if value <= smallest {
            (smallest, second_smallest) = (value, smallest);
        } elif value < second_smallest {
            second_smallest = value;
        }
    }
    return second_smallest;
}