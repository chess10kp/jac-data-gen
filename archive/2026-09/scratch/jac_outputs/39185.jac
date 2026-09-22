"""Calculate the barycenter from a connection vector."""
def get_barycenter(vector: list[int]) -> float | int {
    weighted_sum = 0;
    sum = 0;
    for x in range(len(vector)) {
        if vector[x] {
            weighted_sum += x + 1;
            sum += 1;
        }
    }
    if sum == 0 {
        return -1;
    }
    return weighted_sum / sum;
}