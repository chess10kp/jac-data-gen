def encode_problem_index(function_idx, dimension_idx, instance_idx):
    """
    Compute the problem index for the bbob suite with 15 instances and 24 functions.
    """
    return instance_idx + (function_idx * 15) + (dimension_idx * 15 * 24)

assert encode_problem_index(0, 0, 19) == 19
assert encode_problem_index(0, 0, 9) == 9
assert encode_problem_index(0, 0, 0) == 0
assert encode_problem_index(0, 0, 4) == 4
assert encode_problem_index(0, 0, 30) == 30
assert encode_problem_index(0, 1, 0) == 15 * 24
assert encode_problem_index(0, 0, 16) == 16
assert encode_problem_index(0, 0, 3) == 3
assert encode_problem_index(0, 0, 17) == 17
assert encode_problem_index(0, 0, 15) == 15
assert encode_problem_index(0, 0, 8) == 8
assert encode_problem_index(0, 0, 7) == 7
assert encode_problem_index(1, 1, 0) == 15 * 24 + 15
assert encode_problem_index(0, 0, 1) == 1
assert encode_problem_index(0, 0, 18) == 18
assert encode_problem_index(0, 0, 10) == 10
assert encode_problem_index(0, 0, 11) == 11
assert encode_problem_index(1, 0, 0) == 15
assert encode_problem_index(0, 0, 6) == 6
assert encode_problem_index(0, 0, 2) == 2
assert encode_problem_index(0, 0, 13) == 13
assert encode_problem_index(0, 0, 5) == 5
assert encode_problem_index(0, 0, 14) == 14
assert encode_problem_index(0, 0, 12) == 12
