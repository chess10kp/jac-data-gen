def verify_increasing(arr: Any) -> object {
    if (len(arr) < 2) {
        return False;
    }
    seen = `set();
    prev = arr[0];
    for num in arr {
        if ((num in seen) or (num <= prev)) {
            return False;
        }
        seen.add(num);
        prev = num;
    }
    return True;
}



with entry {
    print(verify_increasing('hello'));
}
