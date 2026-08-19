def contains_duplicate(nums: Any) -> object {
    seen = `set();
    for num in nums {
        if (num in seen) {
            return True;
        }
        seen.add(num);
    }
    return False;
}



with entry {
    print(contains_duplicate('hello'));
    print(contains_duplicate([81]));
}
