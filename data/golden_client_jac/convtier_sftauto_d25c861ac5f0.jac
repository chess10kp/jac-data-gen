def extract_first_three(lst: Any) -> object {
    result = [];
    count = 0;
    for item in lst {
        if (item not in result) {
            result.append(item);
            count += 1;
            if (count == 3) {
                break;
            }
        }
    }
    return result;
}



with entry {
    print(extract_first_three('hello'));
    print(extract_first_three('Racecar'));
    print(extract_first_three('abcabc'));
}
