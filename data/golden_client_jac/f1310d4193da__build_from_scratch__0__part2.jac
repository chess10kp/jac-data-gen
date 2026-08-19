with entry {
    scores = {
        "Alice": 95,
        "Bob": 87,
        "Charlie": 92
    };

    # Loop through keys
    for name in scores {
        print(f"{name}: {scores[name]}");
    }
}
