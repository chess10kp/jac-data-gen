def example() {
    count = 0;
    while count < 3 {
        print(count);
        count += 1;
    }
    # else runs only if the loop finishes without hitting `break`
    count = 0;
    while count < 5 {
        if count == 3 {
            break;
        }
        count += 1;
    } else {
        print("completed without break");
    }
}
