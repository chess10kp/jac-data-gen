def bitwise_sum(nums: Any) -> object {
    total = 0;
    carry = 0;
    for num in nums {
        total ^= num;
        carry |= num & carry;
        carry <<= 1;
    }
    while carry {
        total ^= carry;
        carry <<= 1;
    }
    return total;
}



with entry {
    print(bitwise_sum([1, 2, 3, 4]));
    print(bitwise_sum([1, 2, 3]));
    print(bitwise_sum([5, 5, 5]));
}
