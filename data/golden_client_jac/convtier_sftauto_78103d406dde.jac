def remove_last_item(arr: Any) -> object {
    if (len(arr) == 0) {
        return arr;
    }
    new_arr = [];
    for i in range((len(arr) - 1)) {
        new_arr.append(arr[i]);
    }
    return new_arr;
}



with entry {
    print(remove_last_item('hello'));
    print(remove_last_item('Racecar'));
    print(remove_last_item('abcabc'));
}
