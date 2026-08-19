def find_max_index(numbers: Any) -> object {
    if (len(numbers) == 0) {
        raise EmptyArrayError("Array is empty");
    }
    max_num = numbers[0];
    max_index = 0;
    for i in range(1, len(numbers)) {
        if (numbers[i] > max_num) {
            max_num = numbers[i];
            max_index = i;
        }
    }
    return max_index;
}



with entry {
    print(find_max_index('hello'));
    print(find_max_index('Racecar'));
    print(find_max_index('abcabc'));
}
