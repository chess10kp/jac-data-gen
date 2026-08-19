def same_orientation(arr: Any) -> object {
    if (len(arr) <= 1) {
        return True;
    } elif (arr[0] == 0) {
        return all((x == 0) for x in arr);
    } else {
        orientation = arr[0] > 0;
        for num in arr {
            if ((num > 0) != orientation) {
                return False;
            }
        }
        return True;
    }
}



with entry {
    print(same_orientation([81]));
    print(same_orientation([-8, -4, 2]));
}
