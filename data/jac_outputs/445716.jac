"""Given a list of input integers, find the (first) two numbers which sum to the given target."""
def find_sum(inputs: list[int], target: int) -> tuple[int, int] | None {
    for i in inputs {
        if i < target // 2 + 1 {
            if target - i in inputs {
                return (i, target - i);
            }
        }
    }
}