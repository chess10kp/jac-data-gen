with entry {
    # Find first number divisible by 7
    for i = 1 to i <= 100 by i += 1 {
        if i % 7 == 0 {
            print(f"Found it: {i}");
            break;  # Exit the loop immediately
        }
    }
}
