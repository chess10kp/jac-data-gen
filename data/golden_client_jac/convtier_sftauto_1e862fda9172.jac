def reorder_array(arr: Any) -> object {
    oddArr = [];
    evenArr = [];
    for num in arr {
        if ((num % 2) == 0) {
            evenArr.append(num);
        } else {
            oddArr.append(num);
        }
    }
    return (oddArr + evenArr);
}



with entry {
    print(reorder_array([]));
}
