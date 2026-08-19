def convert_time(seconds: Any) -> object {
    if (not isinstance(seconds, int) or (seconds <= 0)) {
        raise ValueError("Seconds must be a positive integer.");
    }
    minutes = seconds // 60;
    remaining_seconds = seconds % 60;
    hours = minutes // 60;
    remaining_minutes = minutes % 60;
    return f"{hours} hours, {remaining_minutes} minutes, {remaining_seconds} seconds";
}



with entry {
    print(convert_time(5));
    print(convert_time(10));
    print(convert_time(2));
}
