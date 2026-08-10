"""
    Compare two numeric objects according to the following algorithm:

    1. If float1 < zero_tolerance and float2 < zero_tolerance, then returns True.
    2. If abs(float1) > inf_tolerance and abs(float2) > inf_tolerance, and
       sign(float1) = sign(float2), then returns True.
    3. If zero_tolerance < abs(float1, float2) < inf_tolerance, and
       2*abs(float1 - float2)/(abs(float1) + abs(float2)) <= f_error, return True.
    4. Otherwise, return False.

    :param float1: First numeric field.
    :param float2: Second numeric field.

    :param f_error: Fractional margin of error (default: 0.01)
    :param zero_tolerance: Zero tolerance (default: 1e-8)
    :param inf_tolerance: Infinite tolerance (default: 1e80)
    """
def compare_floats(
    float1: Any,
    float2: Any,
    f_error: Any = 0.01,
    zero_tolerance: Any = 1e-08,
    inf_tolerance: Any = 1e+80
) -> object {
    if ((abs(float1) < zero_tolerance) and (abs(float2) < zero_tolerance)) {
        return True;
    } elif ((abs(float1) > inf_tolerance) and (abs(float2) > inf_tolerance)) {
        if ((float1 / float2) > 0) {
            return True;
        } else {
            return False;
        }
    } elif (((2 * abs((float1 - float2))) / (abs(float1) + abs(float2))) <= f_error) {
        return True;
    } else {
        return False;
    }
}