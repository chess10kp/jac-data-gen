"""
    From the given list of numbers, find the pair of numbers that sum up to 2020.
    This function returns the prduct of those 2 numbers.
    """
def product_of_2(numbers: Any) -> object {
    numbers = [int(item) for item in numbers];
    for i in range(len(numbers)) {
        for j in range((i + 1), len(numbers)) {
            if ((numbers[i] + numbers[j]) == 2020) {
                return (numbers[i] * numbers[j]);
            }
        }
    }
}