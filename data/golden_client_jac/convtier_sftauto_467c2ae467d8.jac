def get_even_elements(A: Any) -> object {
    B = [];
    for element in A {
        if (((element % 2) == 0) and (element not in B)) {
            B.append(element);
        }
    }
    B.sort();
    return B;
}



with entry {
    print(get_even_elements([81]));
    print(get_even_elements([100]));
    print(get_even_elements([-8, -4, 2]));
}
