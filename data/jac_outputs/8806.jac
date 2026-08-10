"""Find minimum number of eggs needed to reach target weight via DP."""
def dp_make_weight(
    egg_weights: tuple[int, ...],
    target_weight: int,
    memo: dict[tuple[tuple[int, ...], int], int] = {}
) -> int {
    subproblem = (egg_weights, target_weight);
    if subproblem in memo {
        return memo[subproblem];
    }
    if egg_weights == () or target_weight == 0 {
        return 0;
    } elif egg_weights[-1] > target_weight {
        result = dp_make_weight(egg_weights[:-1], target_weight, memo);
    } else {
        this_egg = egg_weights[-1];
        num_eggs_with_this_egg = 1 + dp_make_weight(egg_weights, target_weight - this_egg, memo);
        num_eggs_without_this_egg = dp_make_weight(egg_weights[:-1], target_weight, memo);
        if num_eggs_without_this_egg != 0 {
            result = min(num_eggs_with_this_egg, num_eggs_without_this_egg);
        } else {
            result = num_eggs_with_this_egg;
        }
        memo[subproblem] = result;
    }
    return result;
}