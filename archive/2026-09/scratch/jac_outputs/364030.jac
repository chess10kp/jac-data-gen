"""
    Now, the jumps are even stranger: after each jump, if the offset was three or more,
    instead decrease it by 1. Otherwise, increase it by 1 as before.

    Using this rule with the above example, the process now takes 10 steps,
    and the offset values after finding the exit are left as 2 3 2 3 -1.

    How many steps does it now take to reach the exit?
    """
def part2(input_lines: list[str]) -> int {
    jumps = [int(line) for line in input_lines];
    def jump(at: int) -> int {
        to = at + jumps[at];
        if jumps[at] > 2 {
            jumps[at] -= 1;
        } else {
            jumps[at] += 1;
        }
        return to;
    }
    pos = 0;
    count = 0;
    while pos >= 0 and pos < len(jumps) {
        count += 1;
        pos = jump(pos);
    }
    return count;
}