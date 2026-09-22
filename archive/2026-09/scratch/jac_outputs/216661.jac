"""
    Function that calculates the mean of the posterior probability density for non-informative priors.
    More specifically, it is the probability that the stimulus displays value j on dimension i given that it comes from
    category k (equation 3-7 in [Ande90]_)

    Parameters
    ----------
    i : int
        Dimension index
    j : int
        Value on dimension i
    k : int
        Category index. For example, k can be 0 or 1 or 2 etc
    category_membership_list : list
        List of lists that contain the category membership details for the stimuli seen so far. For example, if
        stimuli #0, #1, #4 belongs to category #0 and stimuli #2 and #3 belongs to category #1, then
        category_membership_list = [[0, 1, 4], [2, 3]]
    stimuli : list
        List of lists that contain the stimuli seen so far. For example, after training phase of experiment 1 of
        [MeSc78]_, stimuli = [[1, 1, 1, 1, 1], [1, 0, 1, 0, 1], [0, 1, 0, 1, 1], [0, 0, 0, 0, 0], [0, 1, 0, 0, 0],
        [1, 0, 1, 1, 0]]
    m : list
        List that contains the number of unique values in each dimension. For example, if there are five dimensions and
        all the dimensions are binary, then m = [2, 2, 2, 2, 2]

    Returns
    -------
    float
        The probability that the stimulus displays value j on dimension i given that it comes from category k.
    """
def probability_of_ij_given_k(
    i: int,
    j: int,
    k: int,
    category_membership_list: list[list[int]],
    stimuli: list[list[int]],
    m: list[int]
) -> float {
    nk = len(category_membership_list[k]);
    denominator = nk + m[i];
    count = 0;
    for stim_idx in category_membership_list[k] {
        if stimuli[stim_idx][i] == j {
            count += 1;
        }
    }
    return (count + 1) / denominator;
}