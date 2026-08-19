def calculate_average(numbers: Any) -> object {
    if (len(numbers) == 0) {
        raise EmptyListError("The numbers list is empty.");
    } else {
        def calculate_average_recursive(
            numbers: Any, total: Any = 0, count: Any = 0
        ) -> object {
            if (count == len(numbers)) {
                return (total / count);
            } else {
                total += numbers[count];
                count += 1;
                return calculate_average_recursive(numbers, total, count);
            }
        }
        return calculate_average_recursive(numbers);
    }
}



with entry {
    print(calculate_average([-10368, 1296]));
    print(calculate_average([-10368, -126, 882]));
}
