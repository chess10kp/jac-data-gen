def calculate_surface_area(radius: Any) -> object {
    surface_area = 4 * 3.14159 * (radius ** 2);
    return round(surface_area, 2);
}



with entry {
    print(calculate_surface_area(5));
    print(calculate_surface_area(10));
    print(calculate_surface_area(2));
}
