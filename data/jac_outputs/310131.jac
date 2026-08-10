import from io { TextIOWrapper }

"""Return the open file for given day."""
def puzzle_input(daynumber: int) -> TextIOWrapper[str] | None {
    filename = f"puzzle_inputs/{daynumber}.txt";
    try {
        return open(filename);
    } except FileNotFoundError {
        print(f"Oops - couldn't find '{filename}'");
    }
}