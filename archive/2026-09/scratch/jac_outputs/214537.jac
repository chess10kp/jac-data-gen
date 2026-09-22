"""Attempted optimize for not checking even, but actually marginally slower?"""
def problem_2_try2(limit: int = 4000000) -> int {
    f_1 = 0;
    f_2 = 1;
    even_sum = 0;
    while f_1 < limit {
        even_sum += f_1;
        for _ in range(3) {
            (f_1, f_2) = (f_2, f_2 + f_1);
        }
    }
    return even_sum;
}