def countItems(hashmap: Any) -> object {
    if not hashmap {
        return 0;
    }
    (_, _) = hashmap.popitem();
    count = 1;
    return (count + countItems(hashmap));
}



with entry {
    print(countItems(0));
}
