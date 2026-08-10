"""Smaller error with slightly more compute."""
def rk4_alt_step_func(func: Any, t: Any, dt: Any, y: Any, k1: Any = None) -> object {
    if (k1 is None) {
        k1 = func(t, y);
    }
    k2 = func(
        (t + (dt / 3)), `tuple((y_ + ((dt * k1_) / 3)) for (y_, k1_) in zip(y, k1))
    );
    k3 = func(
        (t + ((dt * 2) / 3)),
        `tuple((y_ + (dt * ((k1_ / -3) + k2_))) for (y_, k1_, k2_) in zip(y, k1, k2))
    );
    k4 = func(
        (t + dt),
        `tuple(
            (y_ + (dt * ((k1_ - k2_) + k3_)))
            for (y_, k1_, k2_, k3_) in zip(y, k1, k2, k3)
        )
    );
    return `tuple(
        ((k1_ + (3 * k2_) + (3 * k3_) + k4_) * (dt / 8))
        for (k1_, k2_, k3_, k4_) in zip(k1, k2, k3, k4)
    );
}