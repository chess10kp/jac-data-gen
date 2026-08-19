def remove_even_duplicates(arr: Any) -> object {
    if (not arr or all(((num % 2) == 0) for num in arr)) {
        return [];
    }
    result = [];
    seen = `set();
    for num in arr {
        if (((num % 2) != 0) and (num not in seen)) {
            result.append(num);
            seen.add(num);
        }
    }
    return result;
}



with entry {
    print(remove_even_duplicates(0));
}
