"""Given two mean squared errors, compute their relative decrease after data augmentation."""
def compute_mse_decrease(mse_before: float, mse_after: float) -> float {
    return (mse_after - mse_before) / mse_before;
}