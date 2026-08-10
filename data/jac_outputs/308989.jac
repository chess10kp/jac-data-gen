"""
Creates a dictionary with for every item in partition for every partition
in partitions the index of partition in partitions.
"""
def partition_to_color(partitions: list[list[str | int]]) -> dict[str | int, int] {
    colors = dict();
    for (color, keys) in enumerate(partitions) {
        for key in keys {
            colors[key] = color;
        }
    }
    return colors;
}