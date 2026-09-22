"""Update a lambda value according to its schedule configuration."""
def update_lambda_value(config: list[tuple[int, float]], n_iter: int) -> float {
    ranges = [
        i
        for i in range(len(config) - 1)
        if config[i][0] <= n_iter < config[i + 1][0]
    ];
    if len(ranges) == 0 {
        assert n_iter >= config[-1][0];
        return config[-1][1];
    }
    assert len(ranges) == 1;
    i = ranges[0];
    (x_a, y_a) = config[i];
    (x_b, y_b) = config[i + 1];
    return y_a + (n_iter - x_a) * float(y_b - y_a) / float(x_b - x_a);
}