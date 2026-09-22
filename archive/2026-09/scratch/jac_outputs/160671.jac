"""
From https://en.wikipedia.org/wiki/Diversity_index#Simpson_index

The measure equals the probability that two entities taken at random from
the dataset of interest represent the same type.
"""
def simpsons_diversity_index(*args: int) -> int {
    if len(args) < 2 {
        return 0;
    }
    def __n_times_n_minus_1(number: int) -> int {
        return number * (number - 1);
    }
    try {
        return int(
            round(
                (
                    1.0
                    - (
                        float(sum(map(__n_times_n_minus_1, args)))
                        / float(sum(args) * (sum(args) - 1))
                    )
                )
                * 100.0
            )
        );
    } except ZeroDivisionError {
        return 0;
    }
}