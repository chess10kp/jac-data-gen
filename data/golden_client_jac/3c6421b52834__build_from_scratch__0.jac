enum Color {
    RED = "red",
    GREEN = "green",
    BLUE = "blue"
}

def describe_color(c: Color) -> str {
    return f"The color is {c.value}";
}

with entry {
    print(describe_color(Color.RED));
}
