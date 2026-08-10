"""Returns true if all the commands succeed."""
def did_commands_succeed(`report: dict[str, list[dict[str, dict[str, int]]]]) -> bool {
    for com in `report['command_set'] {
        if com['result']['status'] != 0 {
            return False;
        }
    }
    True
}