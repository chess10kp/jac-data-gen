def find_consonants(string: Any) -> object {
    consonants = 'bcdfghjklmnpqrstvwxyz';
    i = 0;
    while (i <= (len(string) - len(consonants))) {
        if (string[i:(i + len(consonants))] == consonants) {
            return i;
        }
        i += 1;
    }
    return -1;
}



with entry {
    print(find_consonants('hello'));
}
