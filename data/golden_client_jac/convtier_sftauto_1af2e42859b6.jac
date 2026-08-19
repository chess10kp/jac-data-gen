def flatten_array(arr: Any) -> object {
    flattened = [];
    for sublist in arr {
        if isinstance(sublist, `list) {
            for item in sublist {
                if (isinstance(item, int) and (item >= 0) and ((item % 3) != 0)) {
                    flattened.append(item);
                }
            }
        } elif (isinstance(sublist, int) and (sublist >= 0) and ((sublist % 3) != 0)) {
            flattened.append(sublist);
        }
    }
    return flattened;
}



with entry {
    print(flatten_array('hello'));
}
