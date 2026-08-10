"""Determine the correct salutation using the hour parameter."""
def salutation(hour: int) -> str {
    greetings = (
        (range(0, 12), "Good Morning"),
        (range(12, 17), "Good Afternoon"),
        (range(17, 24), "Good Evening")
    );
    return [greeting for (hours, greeting) in greetings if hour in hours][0];
}