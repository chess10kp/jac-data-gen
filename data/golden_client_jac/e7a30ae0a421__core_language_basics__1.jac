with entry {
    numbers = [1, 2, 3];

    # Length
    print(len(numbers));  # 3

    # Concatenation
    more_numbers = numbers + [4, 5];
    print(more_numbers);  # [1, 2, 3, 4, 5]

    # Repetition
    repeated = [0] * 5;
    print(repeated);  # [0, 0, 0, 0, 0]

    # Membership
    if 2 in numbers {
        print("Found 2!");
    }
}
