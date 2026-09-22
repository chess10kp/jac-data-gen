"""Search through a list of Integers using the selection sorting method."""
def selection_sort(integers: list[int]) -> list[int] {
    integers_clone = list(integers);
    for index in range(len(integers_clone) - 1, 0, -1) {
        max_position = 0;
        for location in range(1, index + 1) {
            if integers_clone[location] > integers_clone[max_position] {
                max_position = location;
            }
        }
        temp = integers_clone[index];
        integers_clone[index] = integers_clone[max_position];
        integers_clone[max_position] = temp;
    }
    return integers_clone;
}