def reverse_and_remove_duplicates(nums: Any) -> object {
    seen = `set();
    result = [];
    for num in reversed(nums) {
        if ((num >= 0) and (num not in seen)) {
            seen.add(num);
            result.append(num);
        }
    }
    return result;
}



with entry {
    print(reverse_and_remove_duplicates([81]));
    print(reverse_and_remove_duplicates([]));
    print(reverse_and_remove_duplicates([100]));
}
