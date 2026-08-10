"""The name of the file containing the targets to probe."""
def targets_key(measurement_uuid: str, agent_uuid: str) -> str {
    f"targets__{measurement_uuid}__{agent_uuid}.csv"
}