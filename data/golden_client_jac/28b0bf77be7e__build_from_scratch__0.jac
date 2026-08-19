with entry {
    numbers = [1, 2, 3];
    numbers[1] = 99;
    print(numbers);  # [1, 99, 3]
    numbers.append(4);
    print(numbers);  # [1, 99, 3, 4]
}
