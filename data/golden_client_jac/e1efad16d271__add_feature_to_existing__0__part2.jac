obj Example {
    has value: int | str | None;
}

def process(data: list[int] | dict[str, int]) -> None {
    # Handle either type
}

# New: union return type helper
def normalize(value: int | str | None) -> str {
    if value is None {
        return "none";
    }
    return str(value);
}

with entry {
    print(normalize(42));
    print(normalize("hi"));
    print(normalize(None));
}
