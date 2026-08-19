def sum_absolute(numbers: Any) -> object {
    if not numbers {
        return 0;
    } elif (len(numbers) == 1) {
        return `abs(numbers[0]);
    } else {
        mid = len(numbers) // 2;
        left_sum = sum_absolute(numbers[:mid]);
        right_sum = sum_absolute(numbers[mid:]);
        return (`abs(left_sum) + `abs(right_sum));
    }
}



with entry {
    print(sum_absolute(0));
    print(sum_absolute([2]));
    print(sum_absolute([34]));
}
