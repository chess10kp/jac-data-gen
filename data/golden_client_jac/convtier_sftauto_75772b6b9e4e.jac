def create_dictionary(lst: Any) -> object {
    dictionary = {};
    for (i, key) in enumerate(lst) {
        if (key not in dictionary) {
            values = sorted(([(int(key) * i)] * (len(key) * i)));
            dictionary[key] = values;
        }
    }
    return dictionary;
}



with entry {
    print(create_dictionary([]));
}
