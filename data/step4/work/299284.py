def scale_relative_risks_for_equivalence(proportions, relative_risks):
    """
    :param proportions: dictionary
    :param relative_risks: dictionary
    :return: dictionary
    """
    new_reference_deno = 0.0
    for stratum in proportions.keys():
        new_reference_deno += proportions[stratum] * relative_risks[stratum]
    new_reference = 1.0 / new_reference_deno
    for stratum in relative_risks.keys():
        relative_risks[stratum] *= new_reference
    return relative_risks

assert scale_relative_risks_for_equivalence({1: 0.5, 2: 0.5}, {1: 2, 2: 2}) == {1: 1, 2: 1}
assert scale_relative_risks_for_equivalence(
    {'a': 0.5, 'b': 1.0, 'c': 0.5},
    {'a': 0.5, 'b': 0.0, 'c': 0.5}
) == {'a': 1.0, 'b': 0.0, 'c': 1.0}
assert scale_relative_risks_for_equivalence(
    {'A': 0.5, 'B': 0.5},
    {'A': 1.0, 'B': 1.0}
) == {'A': 1.0, 'B': 1.0}
assert scale_relative_risks_for_equivalence({1: 0.5, 2: 0.5}, {1: 0.5, 2: 0.5}) == {1: 1, 2: 1}
