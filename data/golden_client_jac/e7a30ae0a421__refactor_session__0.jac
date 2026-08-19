def describe_list(numbers: list) -> None {
    print(len(numbers));
    print(numbers + [4, 5]);
}

def repeat_zero(count: int) -> list {
    return [0] * count;
}

with entry {
    numbers = [1, 2, 3];
    describe_list(numbers);
    print(repeat_zero(5));
    if 2 in numbers {
        print("Found 2!");
    }
}
