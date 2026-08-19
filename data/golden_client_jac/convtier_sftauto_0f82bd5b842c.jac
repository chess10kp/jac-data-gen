def find_second_min(arr: Any) -> object {
    min1 = float('inf');
    min2 = float('inf');
    for num in arr {
        if (num < min1) {
            min2 = min1;
            min1 = num;
        } elif ((num > min1) and (num < min2)) {
            min2 = num;
        }
    }
    return min2;
}



with entry {
    print(find_second_min([-9]));
    print(find_second_min([10, 20]));
    print(find_second_min([-8, -4, 2, 6]));
}
