"""Noop."""
def update(event: dict[str, str], context: dict[str, str]) -> tuple[str, dict[str, str]] {
    return (event["PhysicalResourceId"], {});
}