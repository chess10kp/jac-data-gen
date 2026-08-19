def sort_array(arr: Any) -> object {
    arr.sort();
    return ('[' + ','.join(map(str, arr)) + ']');
}



with entry {
    print(sort_array([]));
    print(sort_array([-10368, 1296]));
    print(sort_array([-10368, -1296, -126, 882]));
}
