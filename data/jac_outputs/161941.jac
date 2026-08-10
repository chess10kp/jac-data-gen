"""Calculate the longest run of repeated adjacent values."""
def run_length(result: list[int]) -> int {
    max_run = 0;
    current_run = 0;
    for i in range(1, len(result)) {
        if result[i] == result[i - 1] {
            current_run += 1;
            if current_run > max_run {
                max_run = current_run;
            }
        } else {
            current_run = 0;
        }
    }
    return max_run;
}