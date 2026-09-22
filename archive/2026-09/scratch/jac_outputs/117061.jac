"""
    Given local, target and outlier density (as estimated by KNN) calculate
    the probability of retaining the event. If local density is less than or
    equal to the outlier density, returns a probability of 0 (event will be
    discarded). If the local density is greater than the outlier density
    but less than the target density, return a value of 1 (absolutely keep this
    event). If the local density is greater than the target density, then
    the probability of retention is the ratio between the target and local
    density.
    """
def prob_downsample(local_d: int, target_d: int, outlier_d: int) -> float {
    if local_d <= outlier_d {
        return 0;
    }
    if local_d <= target_d {
        return 1;
    }
    return target_d / local_d;
}