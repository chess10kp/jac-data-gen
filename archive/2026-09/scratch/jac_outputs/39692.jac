"""Update a running mean estimate with a mini-batch estimate."""
def running_mean_estimate(
    estimate: float | int,
    batch_estimate: float | int,
    num_samples: int,
    batch_size: int
) -> float {
    tot_num_samples = float(num_samples + batch_size);
    estimate_fraction = float(num_samples) / tot_num_samples;
    batch_fraction = float(batch_size) / tot_num_samples;
    return estimate * estimate_fraction + batch_estimate * batch_fraction;
}