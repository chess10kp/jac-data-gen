def remove_words(lst: Any) -> object {
    new_lst = [];
    capitalize_next = False;
    for word in lst {
        if (`any(char.isdigit() for char in word) and word[0].isupper()) {
            continue;
        } elif (word[0].islower() and capitalize_next) {
            new_lst.append(word.title());
            capitalize_next = False;
        } else {
            new_lst.append(word);
            if word[0].islower() {
                capitalize_next = True;
            }
        }
    }
    return new_lst;
}



with entry {
    print(remove_words('hello'));
    print(remove_words('Racecar'));
    print(remove_words('abcabc'));
}
