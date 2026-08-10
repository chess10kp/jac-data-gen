"""Find any of +-@% prefixed on the command."""
def findmodifiers(command: str) -> tuple[str, bool, bool, bool, bool] {
    realcommand = command.lstrip(' \t\n@+-%');
    modset = set(command[:-len(realcommand)]);
    return (
        realcommand,
        '@' in modset,
        '+' in modset,
        '-' in modset,
        '%' in modset
    );
}