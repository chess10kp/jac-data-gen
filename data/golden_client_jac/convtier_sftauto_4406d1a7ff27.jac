def camel_to_space(camel_str: Any) -> object {
    result = "";
    for i in range(len(camel_str)) {
        if (camel_str[i].isupper() and (i != 0)) {
            result += " " + camel_str[i].lower();
        } else {
            result += camel_str[i];
        }
    }
    return result;
}



with entry {
    print(camel_to_space('hello'));
    print(camel_to_space('Racecar'));
    print(camel_to_space('abcabc'));
}
