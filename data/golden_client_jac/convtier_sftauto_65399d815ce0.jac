def swap_elements(arr: Any) -> object {
    if (len(arr) < 6) {
        return arr;
    }
    sum_01 = arr[0] + arr[1];
    sum_34 = arr[3] + arr[4];
    diff = max(arr) - min(arr);
    if ((sum_01 > sum_34) and (diff <= 10)) {
        (arr[2], arr[4]) = (arr[4], arr[2]);
    }
    return arr;
}



with entry {
    print(swap_elements('hello'));
    print(swap_elements('level'));
    print(swap_elements([81]));
}
