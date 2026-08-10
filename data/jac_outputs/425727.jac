"""
Count the number of times a depth measurement increases from the previous measurement
How many measurements are larger than the previous measurement?
"""
def part1(depths: list[int]) -> int {
    depth_increases = 0;
    previous_depth = depths[0];
    for depth in depths {
        if depth > previous_depth {
            depth_increases += 1;
        }
        previous_depth = depth;
    }
    return depth_increases;
}