"""Find indices of two elements whose sum equals target_sum."""
def find_two_sum(numbers: list[int], target_sum: int) -> tuple[int, int] | None {
    taken: dict[int, int] = {};
    for (i, num) in enumerate(numbers) {
        diff = target_sum - num;
        if diff in taken {
            return (i, taken[diff]);
        }
        taken[num] = i;
    }
    None
}