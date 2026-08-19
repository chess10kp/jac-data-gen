def double(numbers: Any) -> object {
    return [(num * 2) for num in numbers];
}



with entry {
    print(double('hello'));
    print(double('Racecar'));
    print(double('abcabc'));
}
