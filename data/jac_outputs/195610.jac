"""
Returns whether two numbers are nearly equal within sig_fig decimal places.

http://stackoverflow.com/questions/558216/function-to-determine-if-two-numbers-are-nearly-equal-when-rounded-to-n-signific
"""
def nearly_equal(a: float, b: float, sig_fig: int = 5) -> bool {
    return a == b or int(a * (10 ** sig_fig)) == int(b * (10 ** sig_fig));
}