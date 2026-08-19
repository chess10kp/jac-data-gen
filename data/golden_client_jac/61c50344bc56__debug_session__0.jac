with entry {
    # List comprehension
    squares = [x ** 2 for x in range(10)];
    print(f"Squares: {squares}");

    # Dictionary comprehension
    square_dict = {x: x**2 for x in range(5)};
    print(f"Square dict: {square_dict}");

    # String formatting
    name = "Alice";
    age = 25;
    message = f"Hello, {name}! You are {age} years old.";
    print(message);

    # Ternary operator
    result = "adult" if age >= 18 else "minor";
    print(f"Status: {result}");

    # Multiple assignment using tuples
    (x, y) = (10, 20);
    print(f"x={x}, y={y}");

    # Swap values
    (x, y) = (y, x);
    print(f"After swap: x={x}, y={y}");
}
