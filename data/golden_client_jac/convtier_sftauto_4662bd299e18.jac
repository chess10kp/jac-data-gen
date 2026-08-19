def find_sum(numbers: Any) -> object {
    if not numbers {
        raise ValueError("The input list is empty.");
    }
    sum_positive = 0;
    for num in numbers {
        if not isinstance(num, (int, float)) {
            raise ValueError("The input list contains non-numeric values.");
        }
        if (num > 0) {
            sum_positive += num;
        }
    }
    return sum_positive;
}



with entry {
    print(find_sum([81]));
    print(find_sum([100]));
    print(find_sum([-8, -4, 2]));
}
