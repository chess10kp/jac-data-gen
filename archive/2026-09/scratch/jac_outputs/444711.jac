"""Return the list with a running mean across the array, with a given kernel size."""
def running_mean(mylist: list[float], N: int) -> list[float] {
    cumsum: list[float] = [0.0];
    moving_aves: list[float] = [];
    for (i, x) in enumerate(mylist, 1) {
        cumsum.append(cumsum[i - 1] + x);
        if i >= N {
            moving_ave = (cumsum[i] - cumsum[i - N]) / N;
            moving_aves.append(moving_ave);
        }
    }
    return moving_aves;
}