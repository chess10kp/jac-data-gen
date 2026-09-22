"""Returns the number's closest multiple above the threshold."""
def findClosestMultipleAboveThreshold(num: int, threshold: int) -> int {
    while True {
        if threshold % num == 0 {
            return threshold;
        }
        threshold += 1;
    }
}