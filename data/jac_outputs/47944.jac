"""Internal Numba implementation of the Lempel-Ziv (LZ) complexity."""
def _lz_complexity(binary_string: list[int]) -> int {
    complexity = 1;
    prefix_len = 1;
    len_substring = 1;
    max_len_substring = 1;
    pointer = 0;
    while prefix_len + len_substring <= len(binary_string) {
        if binary_string[pointer + len_substring - 1] == binary_string[prefix_len + len_substring - 1] {
            len_substring += 1;
        } else {
            max_len_substring = max(len_substring, max_len_substring);
            pointer += 1;
            if pointer == prefix_len {
                complexity += 1;
                prefix_len += max_len_substring;
                pointer = 0;
                max_len_substring = 1;
            }
            len_substring = 1;
        }
    }
    if len_substring != 1 {
        complexity += 1;
    }
    return complexity;
}