def find_largest_number(numbers: Any) -> object {
    if (len(numbers) == 0) {
        return "List is empty";
    }
    largest = numbers[0];
    for number in numbers[1:] {
        if (number > largest) {
            largest = number;
        }
    }
    return largest;
}



with entry {
    print(find_largest_number('hello'));
    print(find_largest_number('Racecar'));
    print(find_largest_number('abcabc'));
}
