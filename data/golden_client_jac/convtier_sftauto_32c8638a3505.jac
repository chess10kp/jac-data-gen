def calculate_sum(my_set: Any) -> object {
    sum = 0;
    for number in my_set {
        if ((number % 3) == 0) {
            continue;
        }
        sum += number;
    }
    return sum;
}



with entry {
    print(calculate_sum([81]));
    print(calculate_sum([100]));
    print(calculate_sum([-8, -4, 2]));
}
