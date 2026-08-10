""" if there are four of a given number in the rows and columns not shared by the square
    under test, and the number isn't already in the block, that number has to be in the square
    under test (I think) """
def get_four_count_nums(candidates: list[int], disallowed_nums: list[list[int]]) -> list[int] {
    collector: dict[int, int] = {};
    for num in candidates {
        if num not in collector {
            collector[num] = 1;
        } else {
            collector[num] = collector[num] + 1;
        }
    }
    return [key for (key, value) in collector.items() if value == 4 and [key] not in disallowed_nums];
}