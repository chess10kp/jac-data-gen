def calculateCircleArea(radius: Any) -> object {
    MAX_RADIUS = 10 ** 9;
    ROUNDING_FACTOR = 0.5;
    radius_squared = radius * radius;
    area = radius_squared * 4;
    rounded_area = int((area + ROUNDING_FACTOR));
    if (rounded_area > (MAX_RADIUS * 4)) {
        return (MAX_RADIUS * 4);
    } else {
        return rounded_area;
    }
}



with entry {
    print(calculateCircleArea(5));
    print(calculateCircleArea(10));
    print(calculateCircleArea(2));
}
