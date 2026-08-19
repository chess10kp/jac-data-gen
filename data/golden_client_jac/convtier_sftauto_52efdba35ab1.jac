def identify_types(data: Any) -> object {
    types = [];
    for element in data {
        if isinstance(element, int) {
            types.append("number");
        } elif isinstance(element, str) {
            if element.isalpha() {
                types.append("alphabet");
            } else {
                types.append("special character");
            }
        } else {
            types.append("unknown");
        }
    }
    return types;
}



with entry {
    print(identify_types('hello'));
    print(identify_types('Racecar'));
    print(identify_types('abcabc'));
}
