"""Calculate volume at time t given envelope env

    envelope is a list of [time, volume] points
    time is measured in samples
    envelope should be sorted by time

    """
def calc_vol(t: float, env: list[list[float]]) -> float {
    if len(env) == 0 {
        return 1.0;
    }
    if len(env) == 1 {
        return env[0][1];
    }
    n = 0;
    while n < len(env) and env[n][0] < t {
        n += 1;
    }
    if n == 0 {
        return env[0][1];
    }
    if n == len(env) {
        return env[-1][1];
    }
    f = float(t - env[n - 1][0]) / (env[n][0] - env[n - 1][0]);
    return env[n - 1][1] * (1.0 - f) + env[n][1] * f;
}