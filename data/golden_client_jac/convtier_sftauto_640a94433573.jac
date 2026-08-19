def filter_list(lst: Any) -> object {
    vowels = ['a', 'e', 'i', 'o', 'u'];
    filtered_list = [];
    for word in lst {
        if ((word[0] != 'S') or (word[-1].lower() not in vowels)) {
            if not `any((char.isdigit() or not char.isalpha()) for char in word) {
                if (word not in filtered_list) {
                    filtered_list.append(word);
                }
            }
        }
    }
    return filtered_list;
}



with entry {
    print(filter_list('hello'));
    print(filter_list('Racecar'));
    print(filter_list('abcabc'));
}
