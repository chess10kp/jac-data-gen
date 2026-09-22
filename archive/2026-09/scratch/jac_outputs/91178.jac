"""Gets the name of the tool that was used and that delivered the log."""
def get_tool_name(header: str) -> tuple[str, str] {
    parts = header.split(":");
    return (parts[1].strip(), ":".join(parts[2:]));
}