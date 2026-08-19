def calculate_surface_area(side_length: Any) -> object {
    if (side_length < 0) {
        raise ValueError("Side length cannot be negative");
    }
    volume = side_length * side_length * side_length;
    face_area = volume >> 1;
    return (face_area << 1);
}



with entry {
    print(calculate_surface_area(5));
    print(calculate_surface_area(10));
    print(calculate_surface_area(2));
}
