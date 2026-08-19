def double_array(arr: Any) -> object {
    result = `set();
    for num in arr {
        result.add((num * 2));
    }
    return sorted(`list(result));
}



with entry {
    print(double_array('hello'));
    print(double_array('Racecar'));
    print(double_array('abcabc'));
}
