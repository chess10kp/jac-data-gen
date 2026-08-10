"""Converts gathered event data to Outlook-API consumable weekday string."""
def outlook_days_of_week(event_data: dict[str, str]) -> list[str] {
    [
        day for (key, day) in [
            ("Sun", "Sunday"),
            ("Mon", "Monday"),
            ("Tue", "Tuesday"),
            ("Wed", "Wednesday"),
            ("Thu", "Thursday"),
            ("Fri", "Friday"),
            ("Sat", "Saturday"),
        ] if event_data[key] == "TRUE"
    ]
}