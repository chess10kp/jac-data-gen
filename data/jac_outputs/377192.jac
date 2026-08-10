"""Remove the top heap item and restore the heap property."""
def remove_top_item(values: list[float], count: int) -> float {
    result = values[0];
    values[0] = values[count - 1];
    index = 0;
    while True {
        child1 = 2 * index + 1;
        child2 = 2 * index + 2;
        if child1 >= count {
            child1 = index;
        }
        if child2 >= count {
            child2 = index;
        }
        if values[index] >= values[child1] and values[index] >= values[child2] {
            break;
        }
        swap_child = child1 if values[child1] > values[child2] else child2;
        (values[index], values[swap_child]) = (values[swap_child], values[index]);
        index = swap_child;
    }
    return result;
}