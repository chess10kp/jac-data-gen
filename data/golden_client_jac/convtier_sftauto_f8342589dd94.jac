def square_and_sort(arr: Any) -> object {
    arr.sort();
    output = [];
    for num in arr {
        output.append((num ** 2));
    }
    output.reverse();
    return output;
}



with entry {
    print(square_and_sort([-9, 2]));
    print(square_and_sort([2]));
    print(square_and_sort([34]));
}
