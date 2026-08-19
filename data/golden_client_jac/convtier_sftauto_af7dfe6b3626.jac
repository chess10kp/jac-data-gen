def group_pairs(arr: Any) -> object {
    if ((len(arr) % 2) == 1) {
        arr.pop();
    }
    pairs = [];
    for i in range(0, len(arr), 2) {
        pair = (arr[i], arr[(i + 1)]);
        pairs.append(pair);
    }
    pairs.sort(reverse=True);
    return pairs;
}



with entry {
    print(group_pairs('abcabc'));
    print(group_pairs([]));
    print(group_pairs([2, -4]));
}
