"""
Calculate value of alpha used in loss based on the epoch.
"""
def alpha_weight(epoch: float, T1: float, T2: float, af: float) -> float {
    if epoch < T1 {
        return 0.0;
    } elif epoch > T2 {
        return af;
    } else {
        return (epoch - T1) / (T2 - T1) * af;
    }
}