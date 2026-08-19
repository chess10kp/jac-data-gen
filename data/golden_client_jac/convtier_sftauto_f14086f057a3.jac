def sum_of_odd_cubes(nums: Any) -> object {
    odd_cubes_sum = 0;
    for num in nums {
        if ((num % 2) != 0) {
            odd_cubes_sum += num ** 3;
        }
    }
    return odd_cubes_sum;
}



with entry {
    print(sum_of_odd_cubes([4, 2, 1]));
    print(sum_of_odd_cubes([5, 5, 5]));
    print(sum_of_odd_cubes([10, 20, 30]));
}
