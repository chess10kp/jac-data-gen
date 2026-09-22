"""
		It repeatedly swaps adjacent elements that are out of order
		it has O(n2) time complexity
		larger numbers are sorted first
	"""
def bubbleSort_decr1(array: list[int]) -> list[int] {
    for i in range(len(array)) {
        for j in range(len(array) - 1, i, -1) {
            if array[j - 1] < array[j] {
                (array[j], array[j - 1]) = (array[j - 1], array[j]);
            }
        }
    }
    return array;
}