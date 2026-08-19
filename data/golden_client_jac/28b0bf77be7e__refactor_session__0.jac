def demo_list_ops() -> None {
    numbers = [1, 2, 3];
    numbers[1] = 99;
    print(numbers);
    numbers.append(4);
    print(numbers);
    numbers.insert(0, 0);
    print(numbers);
    numbers.remove(99);
    print(numbers);
    numbers.pop(0);
    print(numbers);
}

with entry {
    demo_list_ops();
}
