def calculate_area(radius: Any) -> object {
    pi = 3.1415;
    area = pi * (radius ** 2);
    return area;
}



with entry {
    print(calculate_area(5));
    print(calculate_area(10));
    print(calculate_area(2));
}
