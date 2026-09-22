"""Cleans and sets new style division for calculations procedures."""
def process_procedure(procedure: str) -> str {
    return "\n".join([procedure, "\n"]).replace('\r', '\n');
}