def example() {
    count = 0;

    while count < 3 {
        print(count);
        count += 1;
    }

    # With else clause (executes if loop completes normally)
    count = 0;
    while count < 3 {
        count += 1;
    } else {
        print("completed");
    }
}
