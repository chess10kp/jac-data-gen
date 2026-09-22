"""L, a list of integers, at least one positive. Returns the maximum sum of a contiguous subsequence in L."""
def max_contig_sum(L: list[int]) -> int {
    max_contiguous_sum = 0;
    point = 0;
    for subsequence in range(len(L)) {
        current_subsequence = [];
        for (index, number) in enumerate(L[point:]) {
            if not current_subsequence and number <= 0 {
                continue;
            } else {
                try {
                    if sum(current_subsequence) + number > sum(current_subsequence) or sum(current_subsequence) + L[(index + 1)] > sum(current_subsequence) + number {
                        current_subsequence.append(number);
                        if sum(current_subsequence) > max_contiguous_sum {
                            max_contiguous_sum = sum(current_subsequence);
                        }
                    } else {
                        current_subsequence = [];
                    }
                } except IndexError {
                    if sum(current_subsequence) + number > sum(current_subsequence) {
                        current_subsequence.append(number);
                        if sum(current_subsequence) > max_contiguous_sum {
                            max_contiguous_sum = sum(current_subsequence);
                        }
                    }
                }
            }
        }
        point += 1;
    }
    return max_contiguous_sum;
}