enum Color {
    RED = "red",
    GREEN = "green",
    BLUE = "blue"
}

# With auto values
enum Status {
    PENDING,
    ACTIVE,
    COMPLETED
}

with entry {
    # Usage
    color = Color.RED;
    status = Status.ACTIVE;
    print(f"Color: {color}, Status: {status}");
}
