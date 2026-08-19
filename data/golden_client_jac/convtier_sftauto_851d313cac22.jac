def find_minimum(arr: Any) -> object {
    return arr[0]
        if (len(arr) == 1)
        else find_minimum(arr[1:]) if (arr[0] < arr[1]) else find_minimum(arr[1:]);
}



with entry {
    print(find_minimum([81]));
    print(find_minimum(['a']));
    print(find_minimum([100]));
}
