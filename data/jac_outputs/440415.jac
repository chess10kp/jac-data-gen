"""Takes any MAPDL command and returns the first 4 characters of the command"""
def parse_to_short_cmd(command: str) -> str | None {
    try {
        short_cmd = command.split(',')[0];
        return short_cmd[:4].upper();
    } except Exception {
        return;
    }
}