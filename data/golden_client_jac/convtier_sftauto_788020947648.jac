def calculate_circle_area(radius: Any) -> object {
    integer_part = int(radius);
    decimal_part = radius - integer_part;
    area_integer_part = 3.14159 * integer_part * integer_part;
    area_decimal_part = 3.14159 * decimal_part * decimal_part;
    return (area_integer_part + area_decimal_part);
}



with entry {
    print(calculate_circle_area(5));
    print(calculate_circle_area(10));
    print(calculate_circle_area(2));
}
