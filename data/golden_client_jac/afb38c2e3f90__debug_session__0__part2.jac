enum Color {
    RED,
    GREEN,
    BLUE
}

enum Status {
    PENDING = "pending",
    ACTIVE = "active",
    COMPLETED = "completed"
}

with entry {
    color = Color.RED;
    status = Status.ACTIVE;

    if color == Color.RED {
        print("It's red!");
    }

    print(status.value);  # active
}
