"""Determines if the error is caused by a missing "vehicles" table."""
def check_for_missing_vehicles_table(error: Exception) -> bool {
    return '"vehicles" does not exist' in str(error);
}