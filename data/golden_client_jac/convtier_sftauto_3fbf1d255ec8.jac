def sum_of_positive_integers(arr: Any) -> object {
    sum = 0;
    for num in arr {
        if (num > 0) {
            sum += num;
        }
    }
    return sum;
}



with entry {
    print(sum_of_positive_integers([-9]));
    print(sum_of_positive_integers([10, 20]));
    print(sum_of_positive_integers([-8, -4, 2, 6]));
}
