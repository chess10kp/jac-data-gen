def shuffle_odd_elements(arr: Any) -> object {
    return arr[1::2][::-1];
}



with entry {
    print(shuffle_odd_elements('hello'));
    print(shuffle_odd_elements('Racecar'));
    print(shuffle_odd_elements('abcabc'));
}
