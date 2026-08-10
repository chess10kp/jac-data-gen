"""
A numerically stable algorithm is given below. It also computes the mean.
This algorithm is due to Knuth,[1] who cites Welford.[2]
"""
def calcMeanSD(useme: list[float | int]) -> tuple[float, float] {
    mean = 0.0;
    M2 = 0.0;
    sd = 0.0;
    n = len(useme);
    if n > 1 {
        for (i, x) in enumerate(useme) {
            delta = x - mean;
            mean = mean + delta / (i + 1);
            M2 = M2 + delta * (x - mean);
        }
        variance = M2 / (n - 1);
        sd = pow(variance, 0.5);
    }
    return (mean, sd);
}