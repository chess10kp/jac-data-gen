def sum_of_even_squares(nums: Any) -> object {
    sum = 0;
    for num in nums {
        if ((num % 2) == 0) {
            sum += num * num;
        }
    }
    return sum;
}



with entry {
    print(sum_of_even_squares([81]));
    print(sum_of_even_squares([100]));
    print(sum_of_even_squares([-8, -4, 2]));
}
