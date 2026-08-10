""" Returns the string mission_id which is composed from the mission_definition and specifics_hash. """
def make_mission_id(mission_definition: str, specifics_hash: str) -> str {
    return f"{mission_definition}-{specifics_hash}";
}