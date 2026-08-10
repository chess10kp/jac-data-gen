"""Validate that the given transaction location PID is valid."""
def transaction_location_validator(transaction_location_pid: str) -> bool {
    return transaction_location_pid == "loc_pid";
}