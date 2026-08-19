with entry {
    fruits = ["apple", "banana", "cherry"];

    # Loop through items
    for fruit in fruits {
        print(f"I like {fruit}");
    }

    # Loop with index
    for i = 0 to i < len(fruits) by i += 1 {
        print(f"{i}: {fruits[i]}");
    }
}
