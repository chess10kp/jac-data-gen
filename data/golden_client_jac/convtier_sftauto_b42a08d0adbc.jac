def find_circle_area(radius: Any) -> object {
    if isinstance(radius, str) {
        return "Invalid input. The radius must be a positive integer or decimal number.";
    } elif (radius <= 0) {
        return "Invalid input. The radius must be a positive integer or decimal number.";
    } elif (radius > (10 ** 9)) {
        return "Invalid input. The radius is too large.";
    }
    radius = round(radius);
    area = math.pi * (radius ** 2);
    return area;
}



with entry {
    print(find_circle_area('hello'));
}
