def num_of_ways_to_climb(n: int, steps: list[int]) -> int {
    if n < min(steps) {
        return 0;
    }
    ways = 0;
    for step in steps {
        if n == step {
            ways += 1;
        } elif n > step {
            ways += num_of_ways_to_climb(n - step, steps);
        }
    }
    return ways;
}