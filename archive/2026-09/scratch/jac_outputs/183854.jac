"""Return the Happy stack name for the specified deployment."""
def get_happy_stack_name(deployment: str) -> str {
    return f"{deployment}-{deployment}stack";
}