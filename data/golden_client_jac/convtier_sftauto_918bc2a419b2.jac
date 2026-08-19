def get_dict_size(dictionary: Any) -> object {
    count = 0;
    for key in dictionary {
        count += 1;
    }
    return count;
}



with entry {
    print(get_dict_size('hello'));
    print(get_dict_size('Racecar'));
    print(get_dict_size('abcabc'));
}
