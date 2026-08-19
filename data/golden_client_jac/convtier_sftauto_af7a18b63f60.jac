def sum_unique_elements(`list: Any) -> object {
    unique_elements = `set();
    sum = 0;
    for element in `list {
        if ((0 < element <= 100) and ((element % 5) == 0)) {
            if (element not in unique_elements) {
                sum += element;
                unique_elements.add(element);
            }
        }
    }
    return sum;
}



with entry {
    print(sum_unique_elements([]));
}
