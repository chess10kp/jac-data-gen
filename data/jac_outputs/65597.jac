"""Get a hexadecimal string of eight characters length for the given integer."""
def get_workflow_id(identifier: int) -> str {
    hex(identifier)[2:].zfill(8).upper()
}