"""returns sum of a list"""
def calc_sum(num: list[int]) -> int {
    sum_num = 0;
    for t in num {
        sum_num = sum_num + t;
    }
    return sum_num;
}