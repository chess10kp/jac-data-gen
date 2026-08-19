enum Color {
    RED = "red",
    GREEN = "green",
    BLUE = "blue"
}
enum Status {
    PENDING,
    ACTIVE,
    COMPLETED
}
def describe(color: Color, status: Status) -> str {
    return f"Color: {color}, Status: {status}";
}
with entry {
    print(describe(Color.RED, Status.ACTIVE));
}
