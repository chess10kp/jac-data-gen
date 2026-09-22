"""Calculate total intake calories based on activity level."""
def total_intake_calories(bmr: float, activity_level: int) -> float {
    ref_activities = [1.2, 1.4, 1.65, 1.95];
    return bmr * ref_activities[activity_level];
}