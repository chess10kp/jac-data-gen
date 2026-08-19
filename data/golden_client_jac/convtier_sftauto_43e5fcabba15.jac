def extract_elements(lst: Any) -> object {
    extracted_elements = [];
    for i in range(3) {
        extracted_elements.append(lst[i]);
    }
    return extracted_elements;
}



with entry {
    print(extract_elements('hello'));
    print(extract_elements('Racecar'));
    print(extract_elements('abcabc'));
}
