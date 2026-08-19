def calculate_circle_area(radius: Any) -> object {
    try {
        radius = float(radius);
        if (radius <= 0) {
            return "Error: Radius must be a positive number";
        }
        area = math.pi * (radius ** 2);
        return "{:.2f}".format(area);
    } except ValueError {
        return "Error: Invalid input. Radius must be a number";
    }
}



with entry {
    print(calculate_circle_area('hello'));
    print(calculate_circle_area(0));
}
