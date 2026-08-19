with entry {
    # Create a tuple
    point = (10, 20);

    # Access like a list
    print(point[0]);  # 10
    print(point[1]);  # 20

    # Unpack into variables
    (x, y) = point;
    print(f"x={x}, y={y}");

    # Can't modify!
    # point[0] = 5;  # ERROR!
}
