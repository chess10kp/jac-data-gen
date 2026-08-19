def find_biggest_number(my_list: Any) -> object {
    if (len(my_list) == 0) {
        return None;
    }
    biggest_number = my_list[0];
    for number in my_list {
        if (number > biggest_number) {
            biggest_number = number;
        }
    }
    return biggest_number;
}



with entry {
    print(find_biggest_number('hello'));
    print(find_biggest_number('Racecar'));
    print(find_biggest_number('abcabc'));
}
