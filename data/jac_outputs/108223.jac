"""Parse the subcommand from the given COMMAND_TEXT, which is everything that
follows `/pickem`.  The subcommand is the option passed to the command, e.g.
'pick' in the case of `/pickem pick`.
"""
def parse_subcommand(command_text: str) -> str {
    command_text.strip().split()[0].lower()
}