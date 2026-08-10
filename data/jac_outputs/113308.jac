"""
    Function to calculate the length in a path determined by several points.

    Input:
     - points      <list> : list  of p_i points where p_i=x_i+J*y_i.


    Output:
     - <float> : the length.

    """
def get_length_c(points: Any) -> object {
    L = 0.0;
    err = 0;
    for j in range(0, (len(points) - 1)) {
        dl = abs((points[j] - points[(j + 1)]));
        L = L + dl;
    }
    return L;
}