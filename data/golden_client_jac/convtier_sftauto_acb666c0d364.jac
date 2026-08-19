def combine_arrays(arr: Any) -> object {
    combinedArray = [];
    arr.sort(key=len);
    for subarr in arr {
        combinedArray.extend(subarr);
    }
    return combinedArray;
}



with entry {
    print(combine_arrays(['a', 'b', 'a']));
}
