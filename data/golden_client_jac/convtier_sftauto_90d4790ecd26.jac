def roll_dice(n: Any) -> object {
    values = [];
    for _ in range(n) {
        values.append(random.randint(1, 6));
    }
    return values;
}



with entry {
    print(roll_dice(0));
}
