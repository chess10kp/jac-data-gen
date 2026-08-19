def filter_array(arr: Any) -> object {
    result = [];
    seen = `set();
    for element in arr {
        if ((`type(element) == str) and element.islower() and (element not in seen)) {
            result.append(element);
            seen.add(element);
        } elif ((`type(element) == float) and (element not in seen)) {
            result.append(element);
            seen.add(element);
        }
    }
    return result;
}



with entry {
    print(filter_array('hello'));
    print(filter_array('Racecar'));
    print(filter_array('abcabc'));
}
