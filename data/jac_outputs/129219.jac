"""invalid_environment message."""
def invalid_environment(expected_environment: str, default_environment: str) -> str {
    return "'{}' is not a valid target environment, defaulting to '{}'.".format(
        expected_environment, default_environment
    );
}