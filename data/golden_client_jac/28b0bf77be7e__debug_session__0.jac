with entry {
    numbers = [1, 2, 3];

    # Change an item
    numbers[1] = 99;
    print(numbers);  # [1, 99, 3]

    # Add to end
    numbers.append(4);
    print(numbers);  # [1, 99, 3, 4]

    # Insert at position
    numbers.insert(0, 0);  # Insert 0 at index 0
    print(numbers);  # [0, 1, 99, 3, 4]

    # Remove by value
    numbers.remove(99);
    print(numbers);  # [0, 1, 3, 4]

    # Remove by index
    numbers.pop(0);  # Remove first item
    print(numbers);  # [1, 3, 4]
}
