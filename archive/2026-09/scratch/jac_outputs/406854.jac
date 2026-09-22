"""
    Purpose: Compute predictions
    Input  : input_feature (x), intercept (w0), slope (w1)
    Output : Predicted output based on estimated intercept, slope and input feature
    """
def get_regression_predictions(input_feature: float, intercept: float, slope: float) -> float {
    return intercept + slope * input_feature;
}