def product_array(arr: Any) -> object {
    if (len(arr) == 0) {
        return 1;
    } else {
        return (arr[0] * product_array(arr[1:]));
    }
}



with entry {
    print(product_array([]));
}
