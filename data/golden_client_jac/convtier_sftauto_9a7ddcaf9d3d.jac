def calculate_area(diameter: Any) -> object {
    if (diameter <= 0) {
        return 0;
    }
    radius = diameter / 2;
    circumference = 2 * 3.14159 * radius;
    area = (circumference * radius) / 2;
    return area;
}



with entry {
    print(calculate_area(5));
    print(calculate_area(10));
    print(calculate_area(2));
}
