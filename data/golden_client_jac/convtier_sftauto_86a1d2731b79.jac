def sum_of_odd_numbers(n: Any) -> object {
    count = 0;
    sum = 0;
    number = 1;
    while (count < n) {
        if ((number % 3) != 0) {
            sum += number;
            count += 1;
        }
        number += 2;
    }
    return sum;
}



with entry {
    print(sum_of_odd_numbers(5));
    print(sum_of_odd_numbers(10));
    print(sum_of_odd_numbers(2));
}
