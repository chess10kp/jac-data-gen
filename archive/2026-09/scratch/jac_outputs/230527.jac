"""Verify a given command is legal."""
def verify_command(command: list[str]) -> tuple[str, str | None] | tuple[bool, str] {
    command_length = len(command);
    if command_length > 0 {
        if command_length == 1 {
            if command[0] in ["Q", "t"] {
                return (command[0], None);
            }
        }
        if command_length == 2 {
            if (
                command[0] == 'S' and command[1] in ["r", "i", "m"]
                or command[0] in ["A", "AR", "d", "D"] and command[1].isnumeric()
            ) {
                return (command[0], command[1]);
            }
        }
    }
    return (False, " ".join(command));
}