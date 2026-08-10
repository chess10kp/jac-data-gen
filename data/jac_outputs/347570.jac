"""Assign values from lines of a data file to keys in a dictionary."""
def process_line(line: str) -> dict[str, str | int] {
    (name, age, state) = line.strip().split(",");
    {"name": name, "age": int(age), "state": state}
}