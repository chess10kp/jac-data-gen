def has_zero_sum(arr: Any) -> object {
    seen_numbers = `set();
    for num in arr {
        if (-num in seen_numbers) {
            return True;
        }
        seen_numbers.add(num);
    }
    return False;
}



with entry {
    print(has_zero_sum([]));
}
