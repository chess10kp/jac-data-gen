def multiply_array_by_sum(nums: Any) -> object {
    array_sum = sum(nums);
    multiplied_array = [(num * array_sum) for num in nums];
    return multiplied_array;
}



with entry {
    print(multiply_array_by_sum([81]));
    print(multiply_array_by_sum([]));
    print(multiply_array_by_sum([100]));
}
