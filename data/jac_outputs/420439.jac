"""Determines if the passed string is a valid RPS choice."""
def valid_user_input(ui: str) -> bool {
    ui in ("rock", "paper", "scissors")
}