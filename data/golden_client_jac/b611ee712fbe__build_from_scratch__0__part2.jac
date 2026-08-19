with entry {
    numbers = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];

    # [start:end] - start is included, end is excluded
    print(numbers[2:5]);   # [2, 3, 4]

    # [:end] - from beginning to end
    print(numbers[:3]);    # [0, 1, 2]

    # [start:] - from start to end of list
    print(numbers[7:]);    # [7, 8, 9]

    # [start:end:step] - with step size
    print(numbers[0:9:2]); # [0, 2, 4, 6, 8]
}
