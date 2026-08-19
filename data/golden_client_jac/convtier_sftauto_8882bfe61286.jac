def is_similarly_oriented(arr: Any) -> object {
    if (len(arr) < 2) {
        return True;
    }
    first = arr[0];
    for num in arr {
        if ((num * first) <= 0) {
            return False;
        }
    }
    return True;
}



with entry {
    print(is_similarly_oriented([]));
}
