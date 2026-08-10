"""Utility functions to compute the median of 3 numbers"""
def median_of_3(num1: Any, num2: Any, num3: Any) -> object {
    return ((num1 + num2 + num3) - min(num1, num2, num3) - max(num1, num2, num3));
}