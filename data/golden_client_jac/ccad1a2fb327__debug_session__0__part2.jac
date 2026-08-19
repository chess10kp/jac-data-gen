with entry {
    # Print only odd numbers
    for i = 1 to i <= 10 by i += 1 {
        if i % 2 == 0 {
            continue;  # Skip even numbers
        }
        print(i);
    }
}
