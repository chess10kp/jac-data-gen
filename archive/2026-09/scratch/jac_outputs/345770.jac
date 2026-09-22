"""Calculate the largest product from continuous
    substring of given length."""
def largest_product(number: str, series: int) -> int {
    if len(number) < series or series < 0 {
        raise ValueError;
    }
    if not series {
        return 1;
    }
    maximum = 0;
    for i in range(len(number) + 1 - series) {
        partial_sum = int(number[i]);
        for j in number[i + 1:i + series] {
            partial_sum *= int(j);
        }
        maximum = max(maximum, partial_sum);
    }
    return maximum;
}