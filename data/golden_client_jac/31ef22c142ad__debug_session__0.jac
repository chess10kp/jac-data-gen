with entry {
    score = 0;
    print(score);    # Shows: 0

    score = 10;
    print(score);    # Shows: 10

    score = score + 5;  # Add 5 to current value
    print(score);    # Shows: 15

    # Shortcut for score = score + 5
    score += 5;
    print(score);    # Shows: 20
}
