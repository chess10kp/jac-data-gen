def find_elements(arr: Any) -> object {
    unique_elements = `set();
    for element in arr {
        if (element[-1] == 's') {
            unique_elements.add(element);
        }
    }
    sorted_elements = sorted(unique_elements);
    return sorted_elements;
}



with entry {
    print(find_elements('hello'));
    print(find_elements('step on no pets'));
}
