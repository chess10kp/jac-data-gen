def array_sum(arr: Any) -> object {
    if (len(arr) == 0) {
        return "Array is empty.";
    } elif (len(arr) == 1) {
        if (arr[0] >= 0) {
            return arr[0];
        } else {
            return 0;
        }
    } elif (arr[0] >= 0) {
        return (arr[0] + array_sum(arr[1:]));
    } else {
        return array_sum(arr[1:]);
    }
}



with entry {
    print(array_sum([]));
}
