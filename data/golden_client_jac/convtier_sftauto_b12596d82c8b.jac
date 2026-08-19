def find_max_difference_pair(A: Any) -> object {
    A.sort();
    min_element = A[0];
    max_element = A[-1];
    for i in range(1, (len(A) - 1)) {
        if (A[i] < min_element) {
            min_element = A[i];
        }
        if (A[i] > max_element) {
            max_element = A[i];
        }
    }
    return [min_element, max_element];
}



with entry {
    print(find_max_difference_pair([81]));
    print(find_max_difference_pair(['a']));
    print(find_max_difference_pair([100]));
}
