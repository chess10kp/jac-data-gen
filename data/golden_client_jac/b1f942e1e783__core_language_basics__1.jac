with entry {
    # If statement
    condition = True;
    other_condition = False;
    if condition {
        print("Condition is true");
    } elif other_condition {
        print("Other condition is true");
    } else {
        print("Neither condition is true");
    }

    # While loop
    count = 0;
    while count < 3 {
        print(f"Count: {count}");
        count += 1;
    }

    # For loop (counting)
    for i = 0 to i < 5 by i += 1 {
        print(f"i: {i}");
    }

    # For loop (iteration)
    collection = ["a", "b", "c"];
    for item in collection {
        print(f"Item: {item}");
    }
}
