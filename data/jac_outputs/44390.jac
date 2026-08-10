"""Sum of positive integers which cannot be written as the sum of two abundant numbers."""
def sum_non_abundant(limit: int = 28124) -> int {
    divisor_sum = [0] * limit;
    for i in range(1, limit) {
        for j in range(i * 2, limit, i) {
            divisor_sum[j] += i;
        }
    }
    abundant_nums = [i for (i, x) in enumerate(divisor_sum) if x > i];
    expressible = [False] * limit;
    for i in abundant_nums {
        for j in abundant_nums {
            if i + j < limit {
                expressible[i + j] = True;
            } else {
                break;
            }
        }
    }
    return sum(i for (i, x) in enumerate(expressible) if not x);
}