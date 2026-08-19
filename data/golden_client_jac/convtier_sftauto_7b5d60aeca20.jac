def find_maximum(arr: Any) -> object {
    if (len(arr) == 0) {
        return None;
    }
    max_num = arr[0];
    for num in arr {
        if (`type(num) != int) {
            return None;
        }
        if (num > max_num) {
            max_num = num;
        }
    }
    return max_num;
}



with entry {
    print(find_maximum([81]));
    print(find_maximum([100]));
    print(find_maximum([-8, -4, 2]));
}
