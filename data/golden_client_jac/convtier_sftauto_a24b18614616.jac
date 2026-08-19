def generate_unique_list(x: Any) -> object {
    unique_list = [];
    for num in x {
        if (num not in unique_list) {
            unique_list.append(num);
        }
    }
    return unique_list;
}



with entry {
    print(generate_unique_list('hello'));
    print(generate_unique_list('Racecar'));
    print(generate_unique_list('abcabc'));
}
