"""
        Using a threshold to flag when there is over/under-fitting.
        Default: 0.20
    """
def error_analysis(err_train: float, err_test: float, threshold: float = 0.2) -> bool {
    if err_test - err_train > threshold {
        print("WARNING: OVER-fitting");
        return False;
    }
    if err_train > threshold {
        print("WARNING: UNDER-fitting");
        return False;
    }
    return True;
}