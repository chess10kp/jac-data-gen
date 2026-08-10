""" bottom up implementation of cut rod memoized algorithm """
def bottom_up_cut_rod(price: list[float], length: int) -> float {
    incomelst = [float('-Inf') for _ in range(length + 1)];
    incomelst[0] = 0;
    for j in range(1, length + 1) {
        income = float('-Inf');
        for i in range(j) {
            income = max(income, price[i] + incomelst[j - i - 1]);
        }
        incomelst[j] = income;
    }
    return incomelst[length];
}