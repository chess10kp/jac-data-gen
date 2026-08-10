"""max_pairwise_product gets the two biggest numbers and returns the product of them
TimeComplexity: O(n)
"""
def max_pairwise_product(numbers: list[int]) -> int {
    biggest = -9999999999999;
    second_bigest = -9999999999999;
    for ele in numbers {
        if ele > biggest {
            (biggest, second_bigest) = (ele, biggest);
        } elif ele > second_bigest {
            second_bigest = ele;
        }
    }
    return biggest * second_bigest;
}