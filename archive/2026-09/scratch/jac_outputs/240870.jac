"""
    For example: [194, 106]
    note: summation( p_j * (1 - p_j) ) = 1 - summation( p_j^2 )
    """
def Gini_impurity(splitted_sample: list[int] = []) -> float {
    denominator = sum(splitted_sample);
    if denominator == 0 {
        return 0;
    }
    gini_index = 0.0;
    for count in splitted_sample {
        p_i = count / denominator;
        gini_index += p_i * (1 - p_i);
    }
    return gini_index;
}